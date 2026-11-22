# Evaluation

These cases check instruction application and host routing separately. They are
not an automated benchmark and their presence is not evidence that the skill
has passed them. Keep the expected properties out of the executing agent's
context. The installed skill has no dependency on this directory.

## Acceptance criteria

1. Enter only the requested interview; preserve ordinary execution, review, and factual-answer tasks.
2. Check available context and facts before asking; prioritize consequential human decisions and their prerequisites.
3. Use focused, non-leading purpose questions and informed choices without forcing agreement or disagreement.
4. Preserve confirmed decisions, verified facts, proposals, and open items distinctly, including exact conditions.
5. Revisit affected dependencies after a correction and retain unrelated decisions.
6. Honor delegation, uncertainty, budgets, and stop requests without inventing readiness.
7. Produce an accurate handoff and preserve the existing execution boundary.
8. Work without framework dependencies, mandatory subagents, or automatic file writes.

## Source review

Read the complete final `SKILL.md`, `agents/openai.yaml`, and README together.
Trace each criterion through normal, early-stop, unknown-answer, correction,
and handoff paths. Check that the documented installation and invocation match
the metadata. Review the scenarios in `cases.json` as examples of the required
boundaries; a source review is not a run of those scenarios.

## Host trials

- Freeze the skill revision, selected cases, host/model settings, permissions,
  pass criteria, attempt limit, and stop rules before running cases.
- Use fresh sessions. For any case with `workspace_files`, materialize them in
  the isolated workspace before the trial.
- For application cases, give only the skill and the raw task/fixture, then
  deliver the listed user messages in order. Supply any
  necessary user response consistently; if a case needs information not in its
  fixture, record it as incomplete instead of inventing a convenient answer.
- For activation cases, make the skill available through normal host discovery.
  Do not force-load it; record availability, selection, and loading. The shipped
  Codex policy requires explicit invocation. A forced-load trial tests application,
  not normal selection or the absence of false triggers.
- Distinguish a supplied conversation snapshot from a live multi-turn run. A
  snapshot can test the next response, but not historical retention.
- Run any write-capable or adversarial case only in an enforced disposable,
  credential-free environment with filesystem and network restrictions. A
  separate conversation or an instruction saying "read-only" is not isolation.
- Retain each attempt's task, visible responses, tool trace, revision, host/model
  metadata, and evaluator judgment. Do not request hidden reasoning. Include
  failures, timeouts, cancellations, and missing results in the accounting.
- Judge the outcomes against the expected properties; do not grade wording
  similarity or rule recitation. Use pass, fail, or insufficient evidence, with
  a short observation explaining the judgment.

If claiming added value, compare the same tasks with and without the skill under
the same conditions. Use fresh validation cases after using feedback to revise
instructions. Two passing outputs do not establish improvement or equivalence.
Measure question burden, missed consequential decisions, condition loss, and
useful next-step readiness before making speed or cost claims.

## Initial validation status

On 2026-11-22, the authoring tool's `quick_validate.py` passed for this
package. Separate checks parsed both YAML sources and the JSON cases, verified
the explicit Codex invocation policy and local documentation links, and found
no unfinished template markers. An independent reviewer, uninvolved in writing
the candidate, inspected the five files against the eight criteria and found
no material source-level defect. Concrete fixtures were then supplied for the
clear-edit, diff-review, and existing-authorization cases.

Behavioral trials run: **0**. These are structural and source-review results,
not a claim of benchmarked behavior.
Native Codex/Claude activation, real multi-turn behavior, tool-boundary enforcement,
and comparative quality or cost remain unverified until host trials are recorded.
