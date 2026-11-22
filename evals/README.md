# Evaluation

This directory separates deterministic repository checks, host selection, and
interview behavior. A valid package or a passing schema check does not show that
a model selected or followed the skill. The installed skill has no dependency
on this directory.

## Reproducible repository checks

From the repository root, in a development environment, run:

```sh
python -m pip install -r requirements-dev.txt
skills-ref validate skills/decision-interview
python -X warn_default_encoding -W error::EncodingWarning scripts/validate.py
python -X warn_default_encoding -W error::EncodingWarning -m unittest discover -s tests
```

The reference validator checks the skill package. Repository validation checks
the evaluation schema and related invariants; the tests check that malformed
inputs are rejected and supported inputs remain accepted. The explicit warning
options reject omitted text encodings instead of relying on a UTF-8 default.

The [validation workflow](../.github/workflows/validate.yml) runs structure
checks on Ubuntu and Windows. It records the Python encoding environment and
disables Python's UTF-8 mode for those checks, so Windows can expose dependence
on its default file encoding. A Windows runner does not by itself establish
execution under Korean cp949; report the observed encoding with the result.
Installation checks execute the standalone scripts used by both READMEs:
`tests/test_install.sh` on Ubuntu from a fresh `core.autocrlf=true` checkout,
and `tests/test_install.ps1` under both
PowerShell 7 and Windows PowerShell 5.1 on Windows. They use disposable
destinations without changing `HOME`. They cover copied file contents and layout,
hidden/nested files, literal paths, source resolution outside the repository,
existing and competing destinations, missing required files, copy/verification
failure cleanup and retry, and caller state. Controlled copy and race injections
exercise failure paths; they are not evidence of protection against hostile
same-user path replacement. Native macOS execution is not part of this CI.
Run the relevant checks locally with:

```sh
bash tests/test_install.sh
pwsh -NoProfile -File tests/test_install.ps1
powershell -NoProfile -File tests/test_install.ps1
```

Pushes and pull requests also check local documentation links. External links
are checked only by an explicit `workflow_dispatch` run; they still fail that
manual run when invalid. Network availability and destination rate limits no
longer make an ordinary push or pull request fail. Record external-link results
separately from local checks, and report a skipped job as skipped.

These commands and CI do not call a model, execute the interview cases, or grade
question quality. The earlier authoring-only `quick_validate.py` is not required
to reproduce these checks.

## Acceptance criteria

1. Enter only the requested interview; preserve ordinary execution, review, and factual-answer tasks, including later tasks in the same session.
2. Check available context and facts before asking; prioritize consequential human decisions and their prerequisites.
3. Use focused, non-leading purpose questions and informed choices without forcing agreement or disagreement.
4. Preserve confirmed decisions, verified facts, proposals, and open items distinctly, including exact conditions.
5. Resolve conflicting conditions and revisit affected dependencies after a correction while retaining unrelated decisions.
6. Honor delegation, uncertainty, budgets, and stop requests. Judge sufficient clarity against the intended next action: its scope and consequential constraints are known, material choices are settled or specifically delegated, and remaining unknowns have a bounded treatment or concern later work. Do not turn a forced stop or deferral into a readiness claim.
7. Produce an accurate, appropriately redacted handoff and preserve the execution boundary. A settled choice alone grants no new execution permission; a clear user instruction can grant it during the interview, and an earlier grant may already cover implementation after choices are settled.
8. Work without framework dependencies, mandatory subagents, or automatic file writes.

## Case format

[cases.json](cases.json) uses schema version 2, defined by
[cases.schema.json](cases.schema.json). Unknown fields are rejected. Each case
is one counted scenario; the former combined review/fact input is now two
independent cases. Version 1 consumers must adopt the version 2 fields rather
than silently ignoring host applicability or session resets.

| Field | Required | Meaning |
|---|---|---|
| `id` | Yes | Unique scenario identifier. |
| `kind` | Yes | `activation-positive`, `activation-negative`, `policy-routing`, or `application`. |
| `hosts` | Yes | Eligible profiles from the table below. This is applicability, not evidence that those profiles were tested. |
| `user_messages` | Yes | Task inputs delivered in order, waiting for each assistant response. |
| `fixture` | No | Additional task material supplied as data, including any adversarial reference text. |
| `workspace_files` | No | Relative-path-to-text map within the isolated workspace. File paths must be distinct under case-insensitive comparison. A file cannot also serve as a parent directory. |
| `session_reset` | No | A real new session before the specified 1-based message index, carrying only the preceding assistant handoff. |
| `expected_properties` | Yes | Evaluator-only outcome criteria; never give these to the executing agent. |
| `required_evidence` | Yes | Evaluator-only evidence and execution requirements. |

Do not paste an entire case object into the executing agent's context. Deliver
only the raw task messages, applicable fixture/files, and any carried handoff.
Keep the case ID, expected properties, judgments, and other attempts out of that
context. Deliver later messages only when their turn is reached.

## Host profiles and activation

| Profile | Effective policy | Meaningful checks |
|---|---|---|
| `codex-explicit` | Shipped `allow_implicit_invocation: false`. | Explicit application and policy routing; not description-based natural-language selection. |
| `codex-auto` | A disposable test copy with `allow_implicit_invocation: true`. | Natural-language positive/negative selection and explicit application. Record this override; it is not the shipped policy. |
| `claude-on` | Claude Code invocation mode `on`, with the description available. | Natural-language positive/negative selection and explicit application. |
| `claude-user-invocable-only` | Persisted mode `user-invocable-only`, displayed as `user-only` in `/skills`. | Explicit application and policy routing; not description-based selection. |

The Claude policy names and UI label are described in the
[official skills documentation](https://code.claude.com/docs/en/skills).
Codex's metadata policy is described in the
[official skills guide](https://learn.chatgpt.com/docs/build-skills).
Record the host version and effective settings; stale or competing skill copies
can invalidate the setup.

In the case file, the first message of each application session starts with
`$decision-interview` as a separate token. This also applies to the message
identified by `session_reset.before_message`. Before delivering it in Claude Code,
replace the leading token with `/decision-interview`. Keep the rest of the task
unchanged and retain the delivered input in the trace. Keep the skill name
and both command forms out of every activation and policy-routing user message.

Activation-positive and activation-negative cases run only in automatic
profiles. The separate `policy-routing` case checks that an explicit-only host
does not load the skill from a natural-language request. A policy-disabled
non-selection cannot count as a successful negative description test. Ordinary
assistant questions also do not establish that a skill loaded.

For activation cases, expose the skill through normal host discovery without
forcing its body into context. Record availability, selection, and actual
loading separately. If selection/loading cannot be observed, mark that outcome
unverified. A forced-load trial can test application, but cannot establish
normal selection or absence of false triggers.

## Behavioral trials

- Freeze the skill revision, selected cases and profiles, host/model settings,
  permissions, pass criteria, attempt limit, and stop rules before running.
  Record the packaged revision and any profile-only policy override separately.
- Use fresh sessions. For every case with `workspace_files`, materialize those
  files before the trial. Application cases use the explicit invocation in the
  task; record actual loading. A direct-body substitute must be labeled as such.
- Deliver messages in order. If an unprovided response is necessary, record the
  run as incomplete instead of inventing an answer that makes the case pass.
  Treat listed corrections and stop requests as user steering, not as answers
  to a question the assistant never asked.
- For `session_reset`, run the earlier turns live, retain the actual preceding
  assistant response, and start a new session at `before_message`. Supply only
  that handoff as prior-task evidence, with the skill available normally. Keep
  the original transcript evaluator-only. Do not replace an incomplete handoff
  with a prewritten correct summary. Assess handoff completeness before the
  reset and evidence-grounded recovery after it separately within the case.
- A supplied conversation snapshot tests only the next response. The reset case
  tests live handoff/resumption; neither proves native host compaction behavior.
  A compaction claim needs an observed compaction event and its retained context.
- Run write-capable or adversarial cases only in an enforced disposable,
  credential-free environment with filesystem and network restrictions. A
  separate conversation or an instruction saying "read-only" is not isolation.
  Use only synthetic credentials and contact details in the sensitive case.
- Retain every attempt's delivered inputs, visible responses, tool trace,
  revision, host/model/settings metadata, and evaluator judgment. Do not request
  hidden reasoning. Include failures, timeouts, cancellations, and missing
  results in the accounting. Preserve original judgments when adding revisions.
- Judge observed outcomes, not wording similarity or rule recitation. Report
  `pass`, `fail`, or `insufficient-evidence` with a short observation. Record an
  excluded host/profile as `not-applicable`, never as a pass. Unknown loading or
  incomplete runs remain unscored for the dependent claim.

Report separate counts and denominators for description selection, explicit-
only policy routing, and application. Also separate structural checks from
behavioral case attempts. A final answer can be correct while loading is
unobserved, or a handoff can lose a condition while the resumed agent correctly
marks it unknown; preserve those distinctions.

If claiming added value, compare the same tasks with and without the skill under
the same conditions. If claiming a revision improved behavior, compare original
and revised skill versions with matching setups. Use fresh validation cases
after using case feedback to revise instructions. Two passing outputs do not
establish improvement or equivalence. Measure question burden, missed
consequential decisions, condition loss, and useful next-step readiness before
making speed or cost claims.

## Source review and validation status

Read the complete final `SKILL.md`, `agents/openai.yaml`, and user documentation
together. Trace the criteria through normal, conflict, early-stop, unknown-
answer, correction, and handoff paths. Inspect these cases as examples of the
required boundaries; source review is not a run of them.

The initial revision reported structural checks and an independent source
review on 2026-11-22. The suite now contains **23 scenarios**, including a delayed
reply and a combined-choice design with an unresolved interaction. Its presence
and any passing repository checks do not establish behavioral results.

The review of revision `04880f6` covered the skill, documentation, then-current
19 cases, schema, and validation workflow and reported no material source-level
defect. It did not execute Windows checks or model conversations. The later
review found implicit encoding dependencies in the Python tests and a
PowerShell example that changed the caller's preference variable. That earlier
source review and Ubuntu success did not establish Windows compatibility.
Revision `a6f18d7` added Windows execution, strict encoding warnings, and checks
that extracted and compared the actual PowerShell examples in both READMEs.
The installation follow-up moves that implementation into standalone scripts
and tests Bash as well as both Windows PowerShell hosts. Results must be read
against the revision and environment actually checked; the interview skill and
21 model scenarios are unchanged by this installation follow-up.

**2026-11-22 native run: one attempt, no completed responses or scored cases.**
The [2026-11-22 Codex attempt](results/2026-11-22-native-codex.json) exited during
host initialization with a read-only-filesystem error, before any routing or
model response. Two further planned cases were not attempted after that shared
blocker. The requested model was not resolved, so its support is also unknown.
This is an infrastructure result, not an activation pass or a skill-behavior failure.

In the [2026-11-23 late-reply trial](results/2026-11-23-codex-late-choice.json),
a native Codex text client explicitly invoked the installed skill. Both turns
completed. The observed behavior passed the delayed-reply criteria in one
attempt: after 122 seconds with no intervening question or action, the assistant
accepted the custom answer and closed as requested.

A separate [three-turn planning trial](results/2026-11-23-codex-design-discussion.json)
compared three rules in a common situation, then asked about a concrete consequence
after the user combined elements. The handoff retained the chosen rule and the
remaining open question. This discussion-only variant does not score the original
build-authorized case. Desktop choice-card expiry,
automatic selection, Claude Code behavior, native compaction, tool-boundary
enforcement, and comparative quality or cost remain unverified.
Report actual CI and local-check outcomes against the revision they checked;
do not reuse an old pass as evidence for changed inputs.
