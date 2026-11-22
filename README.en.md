# Decision Interview

[한국어](README.md) · [Changelog](CHANGELOG.md) · [Evaluation](evals/README.md)

A planning conversation can revisit settled choices while leaving consequential decisions unresolved.
A request to “ask me questions” does not specify what to ask first or when to stop.
Decision Interview is a standalone skill that prioritizes unresolved decisions and their prerequisites.
It preserves agreed conditions and closes with decisions, open questions, and a useful next step.

## How it works

- Check the conversation and supplied evidence before asking; separate discoverable facts from human choices.
- Keep pending topics and relevant dependencies in a short, visible conversation recap, normally asking one question at a time.
- Use open questions for intent, concrete alternatives for bounded choices, and examples or counterexamples for consequential assumptions.
- Use a suitable host choice UI when available, or short numbered/named options that accept brief replies and custom answers.
- Separate decisions, verified facts, proposals, and uncertainty; preserve exact quantities, exclusions, exceptions, and ordering.
- Revisit only affected choices after a revision. Resolve conflicting requirements and unclear delegation at the necessary boundary.
- Turn repeated deferrals into evidence gathering or a next step. Exclude credentials and minimize personal information in recaps and handoffs.

There is no fixed question count, ambiguity score, required subagent, MCP server, or automatic file storage.
The skill instructions are in English; the conversation follows the user's language.

### When is it clear enough?

Assess the intended next action: its outcome, scope, and consequential constraints must be specific,
and choices that would change it must be settled or explicitly delegated.
Remaining unknowns must have a bounded treatment that permits that action, or affect only later work.
For example, a performance experiment can be ready while launch remains blocked on its results.
A stop request, exhausted budget, or missing evidence can also end the interview; distinguish
work that can proceed from work that remains blocked.

### Execution authority examples

- After “discussion only,” choosing “Save draft” as a button label records a decision. That choice alone does not authorize a file edit.
- “Now change the button label in `index.html` to Save draft” during the interview authorizes that edit. So does earlier permission to edit that file once the label is settled. Do not ask for the same approval again. Local editing permission does not itself include publication or deployment.

Apply new execution requests, restrictions, and withdrawals; ask only about a material boundary
that remains unclear. Valid user instructions and the host's governing rules and permissions
determine authority; the skill does not grant it.

## Examples

Use this skill when you want an interview to develop an idea or examine a plan.
Ordinary factual questions, code reviews, and fully specified edits should remain those tasks.
Changing the task or asking to stop ends interview mode.

**Develop an idea**

```text
$decision-interview I want a personal reading tracker.
Help me clarify the problem through questions.
```

**Examine a plan**

```text
$decision-interview Review this migration plan through questions.
Focus on downtime and recovery conditions. Do not implement it yet.
```

**Set depth and delegation**

```text
$decision-interview Ask about the choices that could change the outcome.
Use your judgment for UI details, and let us defer what I cannot answer.
```

**Revise a decision during an interview**

```text
I want to change the offline-only decision: online connections are allowed.
Revisit the storage choice that depended on it, but keep CSV export.
```

**End a long interview**

```text
Stop the questions here. Summarize the key decisions and unresolved issues,
including which next steps remain blocked.
```

In Claude Code, replace the initial `$decision-interview` with `/decision-interview`.
A command-free request such as “review my plan through questions” depends on a host configuration
that permits natural-language selection. Installation alone does not prove selection.

## Install

Copy the entire [skills/decision-interview](skills/decision-interview) directory.
[SKILL.md](skills/decision-interview/SKILL.md) contains the instructions;
`agents/openai.yaml` contains Codex display metadata and invocation policy.
The installed skill does not require scripts or development packages.

| Host | Project scope | User scope | Explicit invocation |
|---|---|---|---|
| Codex CLI / IDE | `.agents/skills/decision-interview/` | `~/.agents/skills/decision-interview/` | `$decision-interview` |
| Claude Code | `.claude/skills/decision-interview/` | `~/.claude/skills/decision-interview/` | `/decision-interview` |

Download or clone this repository. Run one of these **new-install commands from its root**.
The default destination is the user-level Codex directory. For Claude Code, replace `.agents`
with `.claude`; for project scope, set the destination inside the intended project.
Install in the environment running the host, especially when using both Windows and WSL.

**Bash — macOS / Linux / WSL**

```bash
(
  set -eu
  skill_parent="$HOME/.agents/skills"
  skill_target="$skill_parent/decision-interview"
  test -f skills/decision-interview/SKILL.md
  mkdir -p "$skill_parent"
  if [ -e "$skill_target" ] || [ -L "$skill_target" ]; then
    printf 'Already exists: %s\n' "$skill_target" >&2
    exit 1
  fi
  mkdir "$skill_target"
  cp -R skills/decision-interview/. "$skill_target/"
)
```

**PowerShell — Windows**

```powershell
& {
    $ErrorActionPreference = "Stop"
    $skillSource = Join-Path (Get-Location) "skills/decision-interview"
    $skillTarget = Join-Path $HOME ".agents/skills/decision-interview"
    if (-not (Test-Path -LiteralPath (Join-Path $skillSource "SKILL.md"))) {
        throw "Run this from the repository root."
    }
    if (Test-Path -LiteralPath $skillTarget) {
        throw "Already exists: $skillTarget"
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $skillTarget) -Force | Out-Null
    New-Item -ItemType Directory -Path $skillTarget -ErrorAction Stop | Out-Null
    Get-ChildItem -LiteralPath $skillSource -Force |
        Copy-Item -Destination $skillTarget -Recurse -ErrorAction Stop
}
```

Both commands stop if the destination already exists and keep their settings and variables
out of the caller's scope. If copying fails partway through, inspect the new destination before retrying.

### After copying and when updating

- Confirm that `SKILL.md` and `agents/openai.yaml` are directly under the destination, without an extra nested directory.
- Check the host's skill list and selected path, including competing copies with the same name.
- Check the invocation policy below and invoke the skill. Discovery, selection, and behavior are distinct checks.
- Before updating, read [CHANGELOG.md](CHANGELOG.md), compare the installed copy, decide which local edits and invocation settings to preserve, and back it up before replacement. The new-install commands deliberately do not overwrite an existing installation.

## Invocation policy

| Host / setting | Command-free selection | Explicit invocation |
|---|---|---|
| Shipped Codex policy: `allow_implicit_invocation: false` | Disabled | Enabled |
| Codex installed copy changed to `true` | Description-based selection allowed | Enabled |
| Claude personal/project skill: `on` or no override | Description-based selection allowed | Enabled |
| Claude: `user-invocable-only` | Disabled | Enabled |

Codex policy lives in [agents/openai.yaml](skills/decision-interview/agents/openai.yaml).
To opt into natural-language selection, change the setting to `true` in your installed copy.
The distributed default remains explicit invocation.

Claude Code's `/skills` menu labels the explicit-only state **`user-only`**.
Its persisted value in `.claude/settings.local.json` is **`user-invocable-only`**.
Merge this entry with existing settings instead of replacing the file:

```json
{
  "skillOverrides": {
    "decision-interview": "user-invocable-only"
  }
}
```

`name-only` exposes only the name, so it cannot test selection from the description;
`off` hides the skill. These overrides apply to personal/project skills, not plugin skills.
The installation commands do not change host settings.

Official references: [Agent Skills specification](https://agentskills.io/specification),
[Codex skills and policy](https://learn.chatgpt.com/docs/build-skills),
[Claude skill overrides](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings).
Checked on 2026-11-22.

## Handoff and next action

The default output is a concise handoff in chat: goal and scope, decisions and reasons,
facts versus proposals, exact constraints, unresolved items and resolution conditions,
and the next action with its existing authorization boundary.
Passwords and API keys are excluded; personal information is limited to what the next task needs.
An existing specification may be updated when that write is already in scope.

For another conversation or skill, provide the handoff and accessible evidence, then state the next task:

```text
Use the handoff below to write a plan.
Preserve confirmed conditions and do not turn open items into settled assumptions.
This step authorizes planning only, not implementation or external publication.
[Handoff]
```

If implementation was already authorized, sufficiently specified work may continue.
Receiving a handoff does not grant new permission. No particular downstream skill or file storage is required.

## Validation

Development checks require Python 3.11+ and Git.
From the repository root, in an isolated Python environment:

```text
python -m pip install -r requirements-dev.txt
skills-ref validate skills/decision-interview
python -X warn_default_encoding -W error::EncodingWarning scripts/validate.py
python -X warn_default_encoding -W error::EncodingWarning -m unittest discover -s tests
```

[GitHub Actions](.github/workflows/validate.yml) checks the skill format, Codex metadata,
evaluation JSON Schema, and validator regression tests on Ubuntu and Windows.
It disables Python UTF-8 mode, records the locale encoding, and treats implicit-encoding
warnings as errors in repository validation and tests. The Windows job also tests the
[actual PowerShell installation examples](tests/test_install.ps1): copied contents, preservation
of existing installations, missing-source rejection, and caller settings.
Rerun that check with PowerShell 7 using `pwsh -NoProfile -File tests/test_install.ps1`.

Pushes and pull requests check local documentation links. External links run only through
Actions **Run workflow** (`workflow_dispatch`), so external outages or rate limits cannot
fail ordinary commit CI. A manually requested external-link check still fails on broken links.

The [evaluation guide](evals/README.md), [21 cases](evals/cases.json), and
[JSON Schema](evals/cases.schema.json) are outside the installed skill.
CI does not converse with models or test natural-language activation.
Actual routing, retention, and question quality need recorded host trials.
Structural validation alone does not establish improved performance or permission isolation.

## Design sources

The interview instructions were written for this repository's scope.
These projects informed the design; they are not runtime dependencies.

| Source | Design contribution |
|---|---|
| [Ouroboros interview](https://github.com/Q00/ouroboros/blob/efedf17ec1f8a12c95e2f44e74001a785917b17a/skills/interview/SKILL.md) · [Seed Closer](https://github.com/Q00/ouroboros/blob/efedf17ec1f8a12c95e2f44e74001a785917b17a/src/ouroboros/agents/seed-closer.md) | Facts versus choices, consequential uncertainty, meaningful closure |
| [Symposium](https://github.com/Q00/Symposium/tree/60037854824e369b004703de30877a6c88530f60) | Meaning, boundaries, interpretation, and restating goals |
| [Matt Pocock grilling](https://github.com/mattpocock/skills/blob/abeeaf95660ba9e8b7c753eb38f441ca707a8823/skills/productivity/grilling/SKILL.md) | Question order based on prerequisite decisions |
| [Superpowers brainstorming](https://github.com/obra/superpowers/blob/22f0b463e7a5e579904dd6211a520321035526f7/skills/brainstorming/SKILL.md) | Intent discovery, choice support, and delegated judgment |
| [Spec Kit clarify](https://github.com/github/spec-kit/blob/a4d571229e164e440f8950cac034607bae7b7518/templates/commands/clarify.md) | Question selection and carrying answers into requirements |
