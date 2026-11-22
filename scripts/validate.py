#!/usr/bin/env python3
"""Validate repository metadata and evaluation data, without model or network calls.

Run skills-ref separately for the Agent Skills package format. Link checks are
owned by lychee. These checks do not execute or grade behavioral scenarios.
"""

import json
from pathlib import Path, PurePosixPath, PureWindowsPath
import sys

from jsonschema import Draft202012Validator, SchemaError
import yaml


ROOT = Path(__file__).resolve().parents[1]
METADATA_SCHEMA = {
    "type": "object",
    "required": ["interface", "policy"],
    "properties": {
        "interface": {
            "type": "object",
            "required": ["display_name", "short_description", "default_prompt"],
            "properties": {
                "display_name": {"type": "string", "minLength": 1},
                "short_description": {
                    "type": "string", "minLength": 25, "maxLength": 64
                },
                "default_prompt": {
                    "type": "string", "pattern": r"\$decision-interview(?![A-Za-z0-9_-])"
                },
            },
        },
        "policy": {
            "type": "object",
            "required": ["allow_implicit_invocation"],
            "properties": {"allow_implicit_invocation": {"const": False}},
        },
    },
}


def unique_object(pairs):
    """Reject duplicate JSON keys instead of discarding earlier values."""
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate object key: {key}")
        result[key] = value
    return result


class UniqueSafeLoader(yaml.SafeLoader):
    pass


def unique_yaml_mapping(loader, node, deep=False):
    loader.flatten_mapping(node)
    result = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if not isinstance(key, str):
            raise ValueError("metadata mapping keys must be strings")
        if key in result:
            raise ValueError(f"duplicate metadata key: {key}")
        result[key] = loader.construct_object(value_node, deep=deep)
    return result


UniqueSafeLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, unique_yaml_mapping
)


def schema_errors(data, schema, label):
    Draft202012Validator.check_schema(schema)
    for error in Draft202012Validator(schema).iter_errors(data):
        location = ".".join(str(part) for part in error.absolute_path) or "<root>"
        yield f"{label}:{location}: {error.message}"


def safe_workspace_path(path):
    """Accept portable relative file names; materializers still need isolation."""
    return (
        isinstance(path, str)
        and bool(path)
        and not PurePosixPath(path).is_absolute()
        and not PureWindowsPath(path).drive
        and not any(char in path for char in ("\\", ":", "\0", "\n", "\r"))
        and all(part not in ("", ".", "..") for part in path.split("/"))
    )


def case_errors(data):
    """Check relationships JSON Schema cannot express without custom keywords."""
    seen = set()
    for case in data["cases"]:
        case_id = case["id"]
        if case_id in seen:
            yield f"evals/cases.json: duplicate case id: {case_id}"
        seen.add(case_id)
        for path in case.get("workspace_files", {}):
            if not safe_workspace_path(path):
                yield f"evals/cases.json:{case_id}: unsafe workspace path: {path!r}"
        reset = case.get("session_reset")
        if reset and reset["before_message"] > len(case["user_messages"]):
            yield f"evals/cases.json:{case_id}: session_reset exceeds message count"


def validate_repo(root):
    errors = []
    try:
        metadata = yaml.load(
            (root / "skills/decision-interview/agents/openai.yaml").read_text(encoding="utf-8"),
            Loader=UniqueSafeLoader,
        )
        errors.extend(schema_errors(metadata, METADATA_SCHEMA, "agents/openai.yaml"))
    except (OSError, ValueError, yaml.YAMLError, SchemaError) as error:
        errors.append(f"agents/openai.yaml: {error}")

    try:
        schema = json.loads(
            (root / "evals/cases.schema.json").read_text(encoding="utf-8"),
            object_pairs_hook=unique_object,
        )
        data = json.loads(
            (root / "evals/cases.json").read_text(encoding="utf-8"),
            object_pairs_hook=unique_object,
        )
        structural_errors = list(schema_errors(data, schema, "evals/cases.json"))
        errors.extend(structural_errors)
        if not structural_errors:
            errors.extend(case_errors(data))
    except (OSError, ValueError, SchemaError) as error:
        errors.append(f"evals: {error}")
    return errors


def main():
    errors = validate_repo(ROOT)
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    print("Repository metadata and evaluation schema checks passed (no behavioral trials).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
