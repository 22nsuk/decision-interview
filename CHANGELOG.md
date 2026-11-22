# Changelog

## 2026-11-23 — Waiting for answers and developing a concrete plan

- Keep a question pending across delays. Use a chat question when the host's choice UI expires or its waiting behavior is unknown.
- Compare alternatives through the same example and explain the consequence and tradeoff of each. Follow up on combined choices when their interaction matters.
- Check a representative use before handing off a concrete plan. Add two evaluation cases covering a delayed reply and a design with an unresolved interaction.

## 2026-11-22 — Portable Bash checkout and evaluation inputs

- Keep Bash scripts in LF on Windows Git checkouts and exercise the installer with `core.autocrlf=true` in CI.
- Validate explicit invocation at the start of each application session, including after a reset. Reject skill-name hints in activation and policy-routing messages.
- Reject workspace fixture files whose paths collide under case-insensitive comparison or serve as another file's parent directory.

## 2026-11-22 — Standalone installers and Bash coverage

### Changed

- Move installation code into `scripts/install.sh` and `scripts/install.ps1`; both READMEs now reference the same scripts with short invocation examples.
- Resolve the source relative to the script and accept an explicit destination without requiring Git or Python for installation.
- Isolate Bash source resolution from inherited `CDPATH` and preserve literal destination names beginning with a hyphen.
- Check both required source files and verify their copied contents before reporting success.
- Clean up incomplete outputs owned by the failing invocation while preserving pre-existing or concurrently claimed destinations.
- Preserve Bash's exclusive `mkdir` reservation. PowerShell copies into an owned staging directory and publishes with a non-overwriting directory move.

### Added

- Ubuntu CI execution of the Bash installer tests and Windows CI execution under both PowerShell 7 and Windows PowerShell 5.1.
- Installation checks for hidden/deep files, literal and non-ASCII paths, missing required files, existing files/directories/links, competing destinations, and copy/verification failure cleanup and retry.

### Review scope

The previous PowerShell test already extracted and compared both README examples; it did not duplicate their installation implementation. The standalone scripts simplify ownership and remove the need for code-block extraction. `$HOME` remains valid in Windows PowerShell 5.1. This change does not alter interview instructions, invocation policy, or model evaluation cases. Native macOS execution and hostile same-user path replacement are outside the exercised installation checks.

## 2026-11-22 — Windows validation and execution boundaries

### Fixed

- Read evaluation JSON explicitly as UTF-8 in Python tests and avoid implicit decoding of subprocess output.
- Scope the PowerShell installation examples so their preference and working variables do not persist in the caller's session.
- Correct the earlier review-status statement: the source review and Ubuntu checks did not exercise Windows and missed the encoding and PowerShell scope issues.

### Changed

- Run structural validation on Ubuntu and Windows, with Python UTF-8 mode disabled and missing encoding declarations treated as errors in repository checks.
- Run external-link checks only on explicit workflow dispatch; keep local-link checks on pushes and pull requests and retain strict failures in manual network checks.
- Keep pending interview topics visible in the conversation and define sufficient clarity relative to the intended next action.
- Distinguish a decision from a new execution request, preserve earlier grants that already cover settled choices, and apply clear permission changes during an interview without redundant approval.

### Added

- Native PowerShell checks of both README examples for installation, existing-destination and missing-source refusal, and caller-scope preservation.
- Two behavioral scenarios for a task switch after interview closure and explicit authorization granted during the interview, bringing the suite to 21 scenarios.
- A multi-turn prior-authorization scenario and visible-queue criteria, plus concrete execution-boundary examples in both READMEs.

### Validation scope

Repository checks and installation-example tests do not execute the model scenarios. Windows runner results must identify their actual encoding; running on Windows alone does not prove Korean cp949 coverage. The previously recorded native Codex attempt still produced no model response or behavioral grade. See [evaluation guidance](evals/README.md) for the distinction and recorded limitations.

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
