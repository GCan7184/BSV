# AGENTS.md — AI / LLM usage policy for the BSV project

This file documents how the team uses generative AI (LLMs, coding agents)
while developing this repository. It is the implementation of the
"Политика использования генеративных моделей и агентов" section from the
course brief.

## Principles

1. **HITL — Human In The Loop is non-negotiable.**
   Every line of AI-generated code is reviewed by a human team member
   before it is committed. Reviewer ≠ author. No "merge from the
   chat window" workflow.

2. **No AI slop.**
   We do not commit boilerplate produced by an LLM "just because it
   compiles." Each function must serve a documented purpose in
   `R/*.R` and be exercised by either a test, a vignette example,
   or a real call from the API / Shiny code.

3. **Tests are mandatory when AI writes code.**
   If a function in `R/` was drafted by an LLM, it MUST have at least
   one corresponding `testthat` test before it can be merged.
   See `tests/testthat/` for the existing battery.

4. **Style guide.**
   - We follow the [tidyverse style guide](https://style.tidyverse.org/).
   - Function names: `snake_case`, verbs first (`fetch_*`, `save_*`,
     `enrich_*`).
   - File names mirror module names (`etl_arxiv.R`, `db_utils.R`,
     `ml_mitre.R`, `api_helpers.R`).
   - All exported functions are documented with `roxygen2`
     (`@param`, `@return`, `@export`, at least one example).
   - Imports go through `importFrom` in `NAMESPACE` — no
     `library()` calls inside `R/`. Library calls are allowed in
     `inst/api/`, `inst/shiny/`, `inst/mcp/` since those run as scripts.

5. **External LLMs are optional, never required at runtime.**
   The default deployment of BSV uses rule-based MITRE enrichment
   (`enrich_mitre_rules`) and does NOT call any external AI service.
   The `enrich_mitre_llm` path is opt-in via `BSV_LLM_PROVIDER`.
   This way the project remains reproducible without API keys.

## Allowed AI tools

| Tool                       | Where it can be used                     |
| -------------------------- | ----------------------------------------- |
| Claude / ChatGPT (web)     | Drafting code, debugging, brainstorming  |
| GitHub Copilot in IDE      | Inline completion                         |
| Local Ollama (production)  | `enrich_mitre_llm` path                   |
| Cursor / Continue.dev      | Refactoring, with peer review afterwards  |

## Forbidden

- Committing API keys to git (use `.env`, which is `.gitignore`d).
- Letting an agent run `git push` autonomously.
- Merging a PR whose author and reviewer are both AI agents.
- Copying chunks of GPL/AGPL code via LLM without acknowledging the
  license — we use only permissive (MIT / Apache 2 / BSD) sources.

## PRD (Product Requirements Document)

The PRD for BSV lives in `README.md` and the project brief PDF. Any
significant change in scope must be reflected there before code is
written for it.

## Review checklist

Reviewer of an AI-assisted PR must confirm:

- [ ] Function has roxygen documentation (`@param`, `@return`, `@export`).
- [ ] At least one test in `tests/testthat/` covers the new behavior.
- [ ] No dead code, no commented-out experiments.
- [ ] No new top-level dependency without updating `DESCRIPTION`.
- [ ] No secrets in the diff (run `git diff | grep -iE 'key|token|password'`).
- [ ] `devtools::check()` is green locally.

---
_Last updated: project Stage 2 (ETL demo)._
