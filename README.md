# Truel-Blueprint

Lean 4 formalization of the **Truel problem** (三人决斗博弈) with a [LeanArchitect](https://github.com/hanwenzhu/LeanArchitect) blueprint.

## The Problem

Three players engage in a sequential shooting game:
- **Player A** (甲): hit rate = 100%
- **Player B** (乙): hit rate = 70%
- **Player C** (丙): hit rate = 30%

Turn order: C → B → A → C → … (cyclic among living players). All players are rational (maximize own survival probability), and this rationality is common knowledge.

## Main Result

**C's optimal first-move strategy is to shoot in the air** (deliberately miss), giving a survival probability of 2811/7900 ≈ 35.6%.

The complete ranking: air > shoot A > shoot B.

## Blueprint

- [Blueprint website](https://Camille1024.github.io/Truel-Blueprint/blueprint/) — interactive documentation with dependency graph
- [Dependency graph](https://Camille1024.github.io/Truel-Blueprint/blueprint/dep_graph_document.html) — visualizes the proof structure

The proof is structured as **backward induction** under common knowledge of rationality:

1. **Duel theory** — two-player alternating duel win probabilities via geometric series
2. **Rationality lemmas** — B rationally shoots A; A rationally shoots B
3. **Strategy analysis** — C's survival probability under each first-move option
4. **Optimality theorem** — shooting in the air dominates all other strategies

## Building locally

```bash
# Install dependencies
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh
pip install leanblueprint

# Build the project
lake build

# Extract blueprint data (via LeanArchitect)
lake build :blueprint

# Generate blueprint website
leanblueprint web

# Preview
python3 -m http.server 8080 --directory blueprint/web
```

## Toolchain

- Lean 4: v4.30.0-rc1
- Mathlib: v4.30.0-rc1
- LeanArchitect: main branch
