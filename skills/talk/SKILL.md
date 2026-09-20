---
name: talk
---
# /talk

A conversation between the user and the agent about the project. The user brings ideas, requirements, concerns, or decisions they want to make. The agent listens, probes, and stores what comes out of it in a useful form.

The output is always something persistent — a spec, a decision record, or GitLab issues. A conversation that produces nothing stored is a conversation that did not happen.

---

## How to approach the conversation

**Probe every product statement until it describes observable outcomes the user can recognise as done or not done.**
"I want it to be fast" is not a requirement. "Responses must return in under 200ms for 95% of requests" is. A requirement is concrete when the user could observe whether it was met. Keep probing until every requirement meets this bar or is explicitly deferred.

**Product decisions belong to the user. Technical decisions belong to the agent.**
Do not ask the user about technical choices. If something is technically unknown, research it or create a GitLab issue to investigate it — do not ask the user.

**When the user makes a technical statement, find the intent behind it — do not record it as a requirement.**
"We need Redis" means the user wants fast, reliable data access — the agent decides if Redis is right. "Use a REST API" means the user wants external access to the system — the agent decides the right interface design. Probe for the underlying product need, then make the technical decision yourself. The user is reaching for technical vocabulary to express what they want. Your job is to find what they want.

**When you do not know something technical, look it up or create an investigation issue.**
If the conversation surfaces a technical unknown that can be answered through research — documentation, changelogs, benchmarks — look it up during the conversation. Create a GitLab issue only for unknowns that require building a prototype, running experiments, or access to production systems. Do not defer to investigation issues what can be answered with five minutes of research.

**Probe for what the user cannot articulate.**
Users often know what they want but cannot express it precisely. Ask for examples. Ask what bad looks like. Ask what they would change about something similar they have used before. Draw out the intent behind the words.

---

## During the conversation

Work through the following areas, but as a dialogue — not a checklist. Follow where the conversation goes. Come back to uncovered areas naturally.

- **What is this about?** — Get the scope of this conversation. Is the user defining something new? Changing something existing? Making a decision?
- **What should it do?** — Concrete behaviour, not abstract qualities.
- **Who is affected?** — Who uses it, who is impacted by it.
- **What are the limits?** — What it must not do, what constraints apply.
- **How do you know it works?** — What would the user observe if this was done correctly?

Keep asking until every product question has a concrete answer or is explicitly deferred.

---

## Early exit

If the user ends the conversation before all questions are answered — they say "that's enough for now", close the session, or stop responding — do not leave things in an undefined state.

1. Write whatever was captured so far. Use `[TBD]` as a placeholder for any unanswered items in a spec. Write partial decision records if a decision was discussed but not fully resolved.
2. For each question that was not answered, create a GitLab issue: title `Pending: <question>`, description with the context gathered so far and what still needs to be decided.
3. Tell the user what was stored and what is still open: "Saved a partial spec for X. Created issues #N and #M for the open questions — we can pick those up next time."

Nothing is lost. The open questions become issues and will surface in the next `/plan` run.

---

## After the conversation

Before writing anything, read all existing specs in `docs/specs/` and all existing decision records in `docs/decisions/`. If the new spec would contradict or overlap with an existing one, resolve the conflict with the user before writing. A new spec that quietly overrides an existing one is worse than no spec.

Decide what to produce based on what was discussed:

**If something new was defined** → write a spec to `docs/specs/<name>.md` following the spec format below.

**If a decision was made** → write a decision record to `docs/decisions/<name>.md` following the decision record format below.

**If tasks were identified** → create GitLab issues. One issue per task. Reference the relevant spec or decision in the issue description.

**If technical unknowns surfaced** → create a GitLab issue for each one. Title: "Investigate: <question>". Description: what needs to be found out, and a suggested approach (write a test, build a prototype, benchmark).

Multiple outputs are normal. A single conversation can produce a spec, several issues, and investigation tickets.

---

## Spec format

```markdown
# <Name>

## Purpose

<What this is and why it exists.>

## Users

<Who uses this and what they are trying to do.>

## Must have

- <Concrete, testable requirement>

## Nice to have

- <Concrete, testable requirement>

## Constraints

- <Constraint>

## Out of scope

- <Explicitly excluded>

## Success criteria

- <Observable outcome>
```

Save to `docs/specs/<name>.md`. Commit: `docs: add <name> spec`

---

## Decision record format

```markdown
# <Decision title>

Date: <YYYY-MM-DD>

## Decision

<What was decided, in one or two sentences.>

## Why

<The reasoning. What alternatives were considered and why this was chosen.>

## Consequences

<What this means going forward — what it enables, what it rules out.>
```

Save to `docs/decisions/<name>.md`. Commit: `docs: add <name> decision record`
