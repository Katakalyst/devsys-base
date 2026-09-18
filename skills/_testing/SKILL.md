---
name: _testing
---
# Testing

How to approach testing in this system. The agent is responsible for test coverage — the user does not manage tests.

---

## The principle

Tests are not optional. Every feature and every bug fix must have tests. A change without tests is not done.

Tests serve two purposes:
1. Confirm the code does what it should right now
2. Catch regressions when other code changes later

Write tests for behaviour, not implementation. Test what the code does, not how it does it internally. This keeps tests useful even when implementation changes.

---

## Coverage expectations

- Every new feature must have tests covering its core behaviour
- Every bug fix must have a test that would have caught the bug — write the test first, confirm it fails, then fix the bug, confirm it passes
- Every edge case mentioned in a spec must have a test
- Do not aim for 100% line coverage — aim for meaningful coverage of behaviour that matters

If a project has no tests at all, add a testing foundation as a separate issue before implementing features. A project without tests cannot be reliably changed.

---

## What to test

**Always test:**
- The happy path — the thing working correctly
- Known failure modes — invalid input, missing data, error conditions
- Boundary conditions — empty collections, zero values, maximum values
- Anything the spec explicitly calls out as required behaviour

**Do not test:**
- Internal implementation details that are likely to change
- Framework or library behaviour — trust that the library works
- Things that are trivially obvious and cannot reasonably fail

---

## Language-agnostic approach

Before writing tests, check what testing framework the project already uses. If none exists, choose the standard one for the language:

| Language | Standard framework |
|----------|--------------------|
| Python | pytest |
| TypeScript / JavaScript | vitest or jest |
| Go | built-in `testing` package |
| Rust | built-in `#[test]` |
| Ruby | rspec |

Use whatever is already in the project. If starting fresh, use the standard for the language — do not introduce unusual choices.

---

## Test structure

Each test should:
1. Set up the state needed
2. Perform the action being tested
3. Assert the expected outcome

Keep tests short and focused. One behaviour per test. If a test is testing five things at once, split it.

Name tests descriptively: `test_user_cannot_login_with_wrong_password` not `test_login_2`.

---

## Running tests

Always run the full test suite before opening an MR:
```
<language-specific test command>
```

All tests must pass before merging. A failing test is a blocker — fix it before continuing.

If a test was already failing before your change: note it, create an issue for it, but do not let it block your current work if it is unrelated.

---

## Tests for existing code

When working on a feature area that has no tests, add tests for the existing behaviour before changing anything. This creates a safety net. It also helps you understand what the code is supposed to do.

If adding tests for existing code would take longer than the current issue warrants, create a separate issue: "Add tests for <area>" and add it to the backlog.
