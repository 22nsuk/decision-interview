# Changelog

## 2026-11-22 — Evaluation and interview follow-up

### Changed

- Clarify natural-language interview requests in the description while preserving the shipped Codex explicit-invocation policy.
- Track pending topics and meaningful dependencies; clarify conflicting conditions, ambiguous delegation, repeated deferral, and context recovery.
- Support suitable host choice UIs, short option replies, and proportionate progress recaps.
- Add an adaptable handoff skeleton and exclude credentials while minimizing personal information.
- Distinguish Claude's `user-only` menu label from the persisted `user-invocable-only` value.

### Added

- Nineteen separately scored scenarios with host profiles, adjacent negatives without answer cues, Korean multi-turn retention, and an actual session-reset protocol.
- A version 2 case format and JSON Schema. Split the previous combined review/factual case; external consumers of the old data should migrate to the documented fields.
- Reproducible development checks using the pinned Agent Skills reference validator, metadata/schema validation, validator regression tests, and GitHub Actions with separate local/external link jobs.
- English documentation, non-overwriting new-install commands for Bash and PowerShell, an installation/update checklist, and next-task handoff examples.

### Validation scope

Deterministic CI validates structure and links. It does not run model conversations or prove natural-language selection, multi-turn reliability, or comparative benefit.
One native Codex attempt stopped during host initialization; no model response or behavioral grade was produced, and two further planned cases were not attempted.
See [evaluation guidance](evals/README.md) for trial requirements and recorded status.

## 2026-11-22 — Initial publication

[Initial skill commit](https://github.com/22nsuk/decision-interview/commit/9f87daac9ae94f0b53dd8c71078e8ac5077259fa).

- Publish the standalone interview instructions, Codex metadata, Korean documentation, and eight evaluation scenarios.
- Record structural validation and independent source review separately from behavioral trials.
