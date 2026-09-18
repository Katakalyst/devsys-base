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
Do not ask the user about technical choices. If something is technically unknown, create a GitLab issue to investigate it.

**When you do not know something technical, create a GitLab issue to investigate it.**
If the conversation surfaces a technical unknown — "can this approach handle that load?", "does this library support that feature?", "is this architecture sound for this use case?" — do not guess and do not ask the user. Create a GitLab issue to investigate it, preferably with a concrete test or spike defined in the issue description.

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

## After the conversation

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
