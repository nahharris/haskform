# AGENTS.md - Haskform Operational Guidelines

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

---

## 1. Project Context

### What is Haskform?

Haskform is an Infrastructure as Code (IaC) framework written in Haskell. It enables users to define infrastructure using Haskell's pure functional paradigm, providing:
- Strong type safety for infrastructure definitions
- Composability through monads and functors
- Predictable state transformations
- Excellent IDE support via Haskell tooling

### Architecture Vision

Inspired by Terraform and Pulumi:
- **Core Engine**: Stateful resource graph execution
- **Providers**: Plugin-based system for cloud/API integration
- **State Management**: Declarative plan/apply workflow
- **Language**: Haskell (not HCL)

### Reference Documentation
- Terraform internals: https://developer.hashicorp.com/terraform/internals
- Pulumi concepts: https://www.pulumi.com/docs/concepts/how-pulumi-works/
- Obsidian vault: `docs/haskform-brain/`

---

## 2. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

---

## 3. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

---

## 4. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

---

## 5. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

## 6. Obsidian as Second Brain

**Always use the Obsidian vault for tracking and research.**

### Workflow
1. **Research**: Create notes in `docs/haskform-brain/research/`
2. **Architecture**: Document decisions in `docs/haskform-brain/architecture/`
3. **Issues**: Log bugs/features in `docs/haskform-brain/issues/`
4. **Todos**: Track progress in `docs/haskform-brain/todos/`

### Issue Tracking Format
```markdown
---
id: issue-N
title: Brief description
status: open | in_progress | closed
priority: high | medium | low
type: bug | feature | refactor
---

## Description

## Steps to Reproduce (if bug)

## Expected Behavior

## Notes
```

### Update Obsidian first when:
- Discovering new technical context
- Making architectural decisions
- Finding bugs or limitations
- Planning significant work

---

## 7. Local CI Requirements

**Always run CI checks before committing.**

### Required Checks
```bash
# Build all targets
mise run build

# Run tests
mise run test

# Lint code
mise run lint
```

### Optional Checks
```bash
# Format code (if using stylish-haskell)
mise run format

# Full CI (includes optional)
mise run ci
```

### CI Must Pass
- Build compiles without errors
- All tests pass
- No HLint warnings (unless explicitly documented)

### Pre-commit Hook (Optional)
```bash
# Install pre-commit hook
cp .git/hooks/pre-commit.sample .git/hooks/pre-commit
```

---

## 8. Haskell Conventions

### Module Structure
```
src/
  Haskform/
    Core/           # Core engine
      State.hs
      Graph.hs
      Plan.hs
    Provider/       # Provider interface
      Types.hs
      Protocol.hs
    CLI/            # Command-line interface
```

### Naming Conventions
- Modules: `CamelCase` (e.g., `Haskform.Core.State`)
- Functions: `camelCase`
- Types: `CamelCase`
- Records: `CamelCase` with `fieldName` accessor style

### Testing
- Use HSpec for test框架
- Place tests in `test/` directory mirroring `src/`
- Follow `Spec.hs` naming convention
- Test behavior, not implementation

### Imports
- Explicit imports preferred over qualified
- Use `Protolude` or `Relude` as base, or bare `Prelude`
- Avoid `unsafe` functions unless necessary

---

## 9. Code Style

### Formatting
- Max line length: 100 characters
- 4-space indentation (no tabs)
- Trailing whitespace prohibited

### Documentation
- Haddock for public APIs
- Inline comments for non-obvious logic
- No docstrings for trivial accessors

### Error Handling
- Use `Either` or `Except` for recoverable errors
- `error` only for programmer errors
- Provide meaningful error messages

---

## 10. Git Workflow

### Commit Messages
- Subject line: 50 characters max
- Use imperative mood ("Add feature" not "Added feature")
- Body only if needed for context

### Branch Naming
- `feature/description`
- `fix/description`
- `refactor/description`

### Pull Requests
- KeepPRs focused and small
- Include tests
- Update documentation if needed

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.