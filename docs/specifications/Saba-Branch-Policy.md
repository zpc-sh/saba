# Saba-Branch-Policy: Multi-Agent Branch Membrane

Last Updated: 2026-04-03

This policy is written for AI contributors first.

## Branch Lanes

1. `agent/*`  
   Local incubation. Wild exploration is allowed. Visibility is optional.
2. `proposal/*`  
   Submission lane. Claims must carry lineage, commitments, and replay pointers.
3. `converge/*` and `main`  
   Convergence lane. Only crystallized, challengeable, replayable artifacts.

## Authority Rules

1. Hidden work is allowed in `agent/*`.
2. Hidden work cannot become authoritative by copy alone.
3. Any merge from `agent/*` to `proposal/*` or `converge/*` must include:
   - commitment references
   - lineage path
   - minimum replay package (L0-L2)

## Naming Conventions

1. `agent/<model>/<topic>`
2. `proposal/<topic>/<date>`
3. `converge/<topic>`

Example:

- `agent/claude/fold-token-experiments`
- `proposal/terminal-fold-semantics/2026-04-03`
- `converge/hall-move-router`

## Intent

Maximize emergence in local lanes, maximize truth integrity in convergence lanes.
