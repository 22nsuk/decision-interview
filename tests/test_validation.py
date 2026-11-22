"""Failure-detection checks for the repository validator, not model behavior."""

from copy import deepcopy
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("repo_validation", ROOT / "scripts/validate.py")
validation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validation)


class ValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.schema = json.loads((ROOT / "evals/cases.schema.json").read_text(encoding="utf-8"))
        cls.cases = json.loads((ROOT / "evals/cases.json").read_text(encoding="utf-8"))

    def setUp(self):
        self.data = deepcopy(self.cases)

    def errors(self):
        return list(validation.schema_errors(self.data, self.schema, "cases"))

    def test_delivered_files_pass(self):
        self.assertEqual([], validation.validate_repo(ROOT))

    def test_optional_inputs_are_optional(self):
        for case in self.data["cases"]:
            for key in ("fixture", "workspace_files", "session_reset"):
                case.pop(key, None)
        self.assertEqual([], self.errors())

    def test_unknown_case_fields_are_rejected(self):
        self.data["cases"][0]["independent_variant"] = "unscored task"
        self.assertTrue(self.errors())

    def test_required_host_and_unknown_host_are_rejected(self):
        case = self.data["cases"][0]
        case.pop("hosts")
        self.assertTrue(self.errors())
        case["hosts"] = ["unknown-host"]
        self.assertTrue(self.errors())

    def test_policy_only_hosts_cannot_score_description_routing(self):
        case = self.data["cases"][0]
        case["kind"] = "activation-negative"
        case["hosts"] = ["codex-explicit"]
        self.assertTrue(self.errors())

    def test_duplicate_ids_are_rejected(self):
        self.data["cases"].append(deepcopy(self.data["cases"][0]))
        self.assertTrue(any("duplicate case id" in e for e in validation.case_errors(self.data)))

    def test_fixture_path_boundaries(self):
        case = self.data["cases"][0]
        case["workspace_files"] = {"fixtures/입력.txt": "", "index.html": "content"}
        self.assertEqual([], self.errors())
        self.assertEqual([], list(validation.case_errors(self.data)))
        for path in ("../outside", "/absolute", "a/../b", "C:/outside", "a\\b", "a//b"):
            with self.subTest(path=path):
                case["workspace_files"] = {path: "fixture"}
                self.assertTrue(list(validation.case_errors(self.data)))

    def test_reset_requires_an_existing_next_message(self):
        case = next(c for c in self.data["cases"] if "session_reset" in c)
        case["session_reset"]["before_message"] = len(case["user_messages"]) + 1
        self.assertTrue(any("exceeds message count" in e for e in validation.case_errors(self.data)))

    def test_metadata_rejects_wrong_policy_and_missing_invocation(self):
        metadata = {
            "interface": {
                "display_name": "Decision Interview",
                "short_description": "Clarify goals and test consequential decisions",
                "default_prompt": "Use $decision-interview for this plan.",
            },
            "policy": {"allow_implicit_invocation": False},
        }
        self.assertEqual([], list(validation.schema_errors(metadata, validation.METADATA_SCHEMA, "meta")))
        for value in (True, "false", 0, None):
            with self.subTest(value=value):
                metadata["policy"]["allow_implicit_invocation"] = value
                self.assertTrue(list(validation.schema_errors(metadata, validation.METADATA_SCHEMA, "meta")))
        metadata["policy"]["allow_implicit_invocation"] = False
        for prompt in ("Use another skill.", "Use $decision-interview-extra."):
            with self.subTest(prompt=prompt):
                metadata["interface"]["default_prompt"] = prompt
                self.assertTrue(list(validation.schema_errors(metadata, validation.METADATA_SCHEMA, "meta")))

    def test_cli_reports_malformed_inputs_and_returns_nonzero(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("scripts/validate.py", "evals/cases.schema.json",
                         "skills/decision-interview/agents/openai.yaml"):
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / name, target)
            cases_file = root / "evals/cases.json"
            cases_file.write_text(json.dumps(self.data), encoding="utf-8")
            command = [sys.executable, str(root / "scripts/validate.py")]
            valid = subprocess.run(command, capture_output=True, timeout=15)
            self.assertEqual(0, valid.returncode, valid.stderr)
            for content in ("{", '{"cases": [], "cases": []}'):
                with self.subTest(content=content):
                    cases_file.write_text(content, encoding="utf-8")
                    result = subprocess.run(command, capture_output=True, timeout=15)
                    self.assertNotEqual(0, result.returncode)
                    self.assertIn(b"evals:", result.stderr)
            cases_file.write_text(json.dumps(self.data), encoding="utf-8")
            metadata = root / "skills/decision-interview/agents/openai.yaml"
            for content in ("interface: [", "policy: {}\npolicy: {}\n"):
                with self.subTest(content=content):
                    metadata.write_text(content, encoding="utf-8")
                    result = subprocess.run(command, capture_output=True, timeout=15)
                    self.assertNotEqual(0, result.returncode)
                    self.assertIn(b"agents/openai.yaml:", result.stderr)


if __name__ == "__main__":
    unittest.main()
