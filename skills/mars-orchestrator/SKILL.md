---
name: mars-orchestrator
description: Coordinate explicitly authorized multi-agent implementation in MARS projects, assign file ownership, supervise integration, and check requirements against actual changes and evidence before delivery.
---

# MARS implementation supervision

Use when the user or project instructions authorize delegation or request supervision of implementation. This skill does not grant permission to create chats, publish, merge, change architecture, or execute physical hardware gates.

## Establish the task

Read applicable `AGENTS.md`, the current source of truth, the feature contract, and the existing diff. Follow the project's documented source precedence. Conversation history helps locate decisions; it does not replace current normative sources.

Identify the requested behavior, its consumers, failure behavior, integration boundaries, and explicit exclusions. Record missing or conflicting normative decisions and finish independent work within the authorized scope. Keep the dependent function safely blocked according to its contract; ask only for the decision actually required.

Choose routine technical details within the authorized scope autonomously. Existing authorization remains valid. Do not require another approval merely because work was delegated or a phase ended.

## Assign ownership

Use the smallest team that helps the task: one implementation agent, an independent reviewer, and an optional specialist. For a small task the principal agent may implement and delegate only review. Add simultaneous implementers only for disjoint files or modules with defined interfaces.

Each assignment must include:

- objective and acceptance criteria;
- authoritative sources and scope limits;
- owned files or responsibility;
- dependencies and integration contracts;
- permitted actions and expected evidence;
- instruction to preserve other agents' and the user's changes.

Use the user's requested model and effort when supported by the available tool. Report unavailable settings accurately. A role name or prompt cannot change the actual configured model.

Do not allow competing writers in the same files or checkout state. The principal agent coordinates shared-file changes and Git operations. Subagents may not widen scope, close physical gates, or bypass contracts.

## Supervise completion

Maintain a compact mapping for each material requirement:

| Requirement | Actual entry point and consumer | Change | Evidence | Remaining limitation |
| --- | --- | --- | --- | --- |

Read the actual diff and relevant surrounding code. Check the path from input through validation, state changes, transport or persistence to the consumer. A helper, unused implementation, declaration, or passing isolated test does not establish integration.

For meaningful behavior, consider normal operation, failure, and an integration boundary when applicable. Use existing relevant tests and project gates only when execution is authorized or required by higher-priority instructions. Do not invent cases merely to fill a checklist. Mark a genuinely irrelevant check as not applicable with a reason.

The reviewer receives the requirement, sources, and actual diff, and checks independently. Findings need a condition, consequence, source location, and confidence. Distinguish introduced defects, existing defects, and improvements outside scope. The principal agent resolves relevant findings and reviews the resulting changes before claiming completion.

An agent's completion message is a report to inspect, not proof. Record commands actually run and their results. Separate static inspection, local tests, build, CI on the final SHA, and physical validation. For Gauge physical gates not performed, use `NÃO EXECUTADO — GATE FÍSICO`.

## Deliver and publish

Update only documentation affected by the authorized change. Preserve reference originals and upstream notices. Follow the project's existing local branch and commit workflow; do not create routine branches or remote operations without the applicable authorization.

Before an authorized publication, review changed paths, final diff, required checks, and source base. If another writer changed the destination, reconcile without force or lost work. Never infer merge permission from permission to commit, push, or open a PR.

Report implemented scope, evidence, base/final revision when applicable, unresolved decisions, physical gates, and publication state. Do not declare completion for requirements that remain unimplemented or unverified; say precisely what remains.
