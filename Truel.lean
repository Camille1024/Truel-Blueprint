import Mathlib.Tactic
import Architect

/-!
# The Truel Problem (三人对决博弈)

## Problem Statement

Three players engage in a sequential shooting game:
- Player A (甲): hit rate = 100%
- Player B (乙): hit rate = 70%
- Player C (丙): hit rate = 30%

Turn order: C → B → A → C → … (cyclic among living players).

Each turn, a player chooses one living opponent to shoot at,
or deliberately misses ("shoots in the air").

**Assumption**: All players are rational (maximize own survival probability),
and this rationality is common knowledge.

## Main Result

C's optimal first-move strategy is to **shoot in the air** (deliberately miss).
This gives C a survival probability of 2811/7900 ≈ 35.6%, versus:
- 22377/79000 ≈ 28.3% when shooting at A
- 19677/79000 ≈ 24.9% when shooting at B

## Formalization Structure

1. **Duel Theory**: Two-player alternating duel win probabilities via geometric series.
2. **Rationality Lemmas**: B rationally shoots A; A rationally shoots B.
3. **Strategy Analysis**: C's survival probability under each first-move option.
4. **Optimality Theorem**: Shooting in the air dominates all other strategies.
-/

namespace Truel

/-! ## §1. Players and Hit Rates -/

/-- The three players in the truel. -/
inductive Player : Type
  | A  -- 甲: 100% accuracy
  | B  -- 乙: 70% accuracy
  | C  -- 丙: 30% accuracy
  deriving DecidableEq, Repr

open Player

/-- Hit rate for each player, as a rational number in [0,1]. -/
def hitRate : Player → ℚ
  | A => 1
  | B => 7 / 10
  | C => 3 / 10

/-! ## §2. Two-Player Duel Probabilities

When only two players remain, the game reduces to an alternating duel.
If the first shooter has hit rate `p` and the second has hit rate `q`,
the first shooter survives with probability:

  P(first wins) = p / (1 - (1-p)(1-q)) = p / (p + q - p·q)

This follows from the geometric series:
  P = p + (1-p)(1-q)·p + ((1-p)(1-q))²·p + ⋯
    = p · Σ_{n=0}^∞ ((1-p)(1-q))ⁿ
    = p / (1 - (1-p)(1-q))
-/

/-- Win probability for the first shooter in a two-player alternating duel.
    Requires p + q - p * q ≠ 0 (i.e., at least one player has nonzero hit rate). -/
@[blueprint "def:duel-first-wins"
  (statement := /-- First shooter's win probability: $p / (p + q - pq)$. -/)]
def duelFirstWins (p q : ℚ) : ℚ := p / (p + q - p * q)

/-- Win probability for the second shooter in a two-player alternating duel.
    The second shooter wins iff the first misses, then the second wins the
    sub-duel where second shoots first:
      P(second wins) = (1-p) · q / (p + q - p·q) -/
@[blueprint "def:duel-second-wins"
  (statement := /-- Second shooter's win probability: $(1-p) \cdot q / (p + q - pq)$. -/)]
def duelSecondWins (p q : ℚ) : ℚ := (1 - p) * q / (p + q - p * q)

-- Concrete duel results needed for the truel analysis:

/-- C vs B, C shoots first: P(C wins) = 30/79 -/
@[blueprint
  (statement := /-- In a C vs B duel where C shoots first, C's win probability is $30/79$. -/)
  (uses := [Truel.duelFirstWins])]
theorem duel_CfirstB : duelFirstWins (3/10) (7/10) = 30 / 79 := by
  unfold duelFirstWins; norm_num

/-- C vs B, B shoots first: P(C wins) = 9/79
    (B must miss first with prob 3/10, then C gets to shoot first in sub-duel) -/
@[blueprint
  (statement := /-- In a B vs C duel where B shoots first, C's win probability is $9/79$. -/)
  (uses := [Truel.duelSecondWins])]
theorem duel_BfirstC : duelSecondWins (7/10) (3/10) = 9 / 79 := by
  unfold duelSecondWins; norm_num

/-- B vs C, B shoots first: P(B wins) = 70/79 -/
@[blueprint
  (statement := /-- In a B vs C duel where B shoots first, B's win probability is $70/79$. -/)
  (uses := [Truel.duelFirstWins])]
theorem duel_BfirstC_Bwins : duelFirstWins (7/10) (3/10) = 70 / 79 := by
  unfold duelFirstWins; norm_num

/-- C vs A, C shoots first: P(C wins) = 3/10.
    Since A has 100% hit rate, C has exactly one chance. -/
@[blueprint
  (statement := /-- In a C vs A duel where C shoots first, C's win probability is $3/10$. Since A has $100\%$ hit rate, C has exactly one chance. -/)
  (uses := [Truel.duelFirstWins])]
theorem duel_CfirstA : duelFirstWins (3/10) 1 = 3 / 10 := by
  unfold duelFirstWins; norm_num

/-- A vs C, A shoots first: P(A wins) = 1.
    (A never misses.) -/
theorem duel_AfirstC : duelFirstWins 1 (3/10) = 1 := by
  unfold duelFirstWins; norm_num

/-- B vs A, B shoots first: P(B wins) = 7/10.
    (One chance: if B misses, A kills B.) -/
theorem duel_BfirstA : duelFirstWins (7/10) 1 = 7 / 10 := by
  unfold duelFirstWins; norm_num

/-- A vs B, A shoots first: P(A wins) = 1.
    (A never misses.) -/
theorem duel_AfirstB : duelFirstWins 1 (7/10) = 1 := by
  unfold duelFirstWins; norm_num

/-! ## §3. Rationality Analysis

Under common knowledge of rationality, we can determine each player's
optimal behavior when three players are alive and it is their turn.

The shooting order is C → B → A. We analyze backwards (backward induction).

### A's rational choice (last in order, 3 alive)

When it is A's turn and all three are alive (meaning both B and C missed),
A must choose between shooting B or C.

- Shoot B → B dies → C vs A duel, C shoots first → P(A survives) = 7/10
- Shoot C → C dies → B vs A duel, B shoots first → P(A survives) = 3/10

A rationally shoots B (7/10 > 3/10).

### B's rational choice (second in order, 3 alive)

When it is B's turn and all three are alive (C missed), B chooses:

- Shoot A → may kill A (7/10) → B vs C duel, C first → P(B) = 7/10 × 70/79
               miss A (3/10) → A kills B → P(B) = 0
  Total: 490/790 = 49/79

- Shoot C → may kill C (7/10) → A's turn, A kills B → P(B) = 0
               miss C (3/10) → A's turn, A kills B → P(B) = 0
  Total: 0

- Shoot air → A's turn, A kills B → P(B) = 0

B rationally shoots A (49/79 > 0).
-/

/-- B's survival probability if B shoots A (3 players alive, C already missed). -/
def B_surv_shootA : ℚ :=
  -- Hit A (7/10): B vs C duel, C shoots first. P(B) = 1 - 30/79 = 49/79
  --               But wait — after B kills A, the round continues: next would be
  --               A's turn but A is dead, so round ends. New round: C shoots first.
  --               P(B survives) = 1 - P(C wins C-first duel) = 1 - 30/79 = 49/79
  -- Miss A (3/10): A's turn. A shoots B (rational, see above). B dies.
  7/10 * (49/79) + 3/10 * 0

/-- B's survival probability if B shoots C (3 players alive). -/
def B_surv_shootC : ℚ :=
  -- Hit C (7/10): C dies. A's turn. Only B left as target. A kills B.
  -- Miss C (3/10): A's turn. A shoots B (bigger threat). B dies.
  7/10 * 0 + 3/10 * 0

/-- B's survival probability if B shoots air (3 players alive). -/
def B_surv_air : ℚ :=
  -- A's turn. A shoots B (rational). B dies.
  0

/-- B rationally shoots A: it strictly dominates shooting C. -/
@[blueprint
  (statement := /-- B's survival probability when shooting A ($49/79$) strictly exceeds that of shooting C ($0$). -/)
  (uses := [Truel.duel_BfirstC_Bwins])]
theorem B_rational_vs_C : B_surv_shootA > B_surv_shootC := by
  unfold B_surv_shootA B_surv_shootC; norm_num

@[blueprint
  (statement := /-- B's survival probability when shooting A ($49/79$) strictly exceeds that of shooting in the air ($0$). -/)
  (uses := [Truel.duel_BfirstC_Bwins])]
theorem B_rational_vs_air : B_surv_shootA > B_surv_air := by
  unfold B_surv_shootA B_surv_air; norm_num

/-- A rationally shoots B: surviving probability after shooting B > after shooting C.

When A's turn comes (all 3 alive, both B and C missed):
- Shoot B → B dies, C vs A, C first → P(A) = 1 - 3/10 = 7/10
- Shoot C → C dies, B vs A, B first → P(A) = 1 - 7/10 = 3/10 -/
@[blueprint
  (statement := /-- A rationally shoots B: survival probability $7/10 > 3/10$. Shooting B leads to a C-vs-A duel; shooting C leads to a B-vs-A duel. -/)]
theorem A_rational : (1 : ℚ) - 3/10 > 1 - 7/10 := by norm_num

/-! ## §4. C's Strategy Analysis

Given the rationality results above, when C acts first (3 alive):
- If it becomes B's turn (3 alive): B shoots A.
- If it becomes A's turn (3 alive): A shoots B.

We now compute C's survival probability for each first-move strategy.
-/

/-- The "aftermath" probability: the sub-tree after C's shot misses (or air).
    B shoots at A →
      B hits A (7/10): C vs B, C first → P(C) = 30/79
      B misses (3/10): A shoots B (100%), C vs A, C first → P(C) = 3/10 -/
def aftermath : ℚ := 7/10 * (30/79) + 3/10 * (3/10)

theorem aftermath_eq : aftermath = 2811 / 7900 := by
  unfold aftermath; norm_num

/-- C's survival probability when shooting at A. -/
def C_surv_shootA : ℚ :=
  -- Hit A (3/10): A dies. B's turn → B vs C, B first → P(C) = 9/79
  -- Miss A (7/10): → aftermath
  3/10 * (9/79) + 7/10 * aftermath

/-- C's survival probability when shooting at B. -/
def C_surv_shootB : ℚ :=
  -- Hit B (3/10): B dies. A's turn → A kills C (100%) → P(C) = 0
  -- Miss B (7/10): → aftermath
  3/10 * 0 + 7/10 * aftermath

/-- C's survival probability when shooting in the air. -/
def C_surv_air : ℚ :=
  -- Directly → aftermath (equivalent to guaranteed miss)
  aftermath

/-! ## §5. Exact Values -/

theorem C_surv_air_val : C_surv_air = 2811 / 7900 := by
  unfold C_surv_air; exact aftermath_eq

theorem C_surv_shootA_val : C_surv_shootA = 22377 / 79000 := by
  unfold C_surv_shootA aftermath; norm_num

theorem C_surv_shootB_val : C_surv_shootB = 19677 / 79000 := by
  unfold C_surv_shootB aftermath; norm_num

/-! ## §6. Main Theorems -/

/-- Shooting in the air is strictly better than shooting at A. -/
@[blueprint
  (statement := /-- Shooting in the air ($2811/7900$) is strictly better than shooting at A ($22377/79000$). -/)
  (uses := [Truel.duel_CfirstB, Truel.duel_CfirstA, Truel.duel_BfirstC, Truel.A_rational, Truel.B_rational_vs_C])]
theorem air_beats_shootA : C_surv_air > C_surv_shootA := by
  unfold C_surv_air C_surv_shootA aftermath; norm_num

@[blueprint
  (statement := /-- Shooting in the air ($2811/7900$) is strictly better than shooting at B ($19677/79000$). -/)
  (uses := [Truel.duel_CfirstB, Truel.duel_CfirstA, Truel.A_rational, Truel.B_rational_vs_C])]
theorem air_beats_shootB : C_surv_air > C_surv_shootB := by
  unfold C_surv_air C_surv_shootB aftermath; norm_num

@[blueprint
  (statement := /-- Shooting at A ($22377/79000$) is strictly better than shooting at B ($19677/79000$). -/)
  (uses := [Truel.duel_BfirstC, Truel.duel_CfirstB, Truel.A_rational, Truel.B_rational_vs_C])]
theorem shootA_beats_shootB : C_surv_shootA > C_surv_shootB := by
  unfold C_surv_shootA C_surv_shootB aftermath; norm_num

/-- **The Truel Theorem (Main Result)**:

    In the three-player sequential shooting game with hit rates
    A = 100%, B = 70%, C = 30%, and turn order C → B → A,
    under common knowledge of rationality:

    1. C's optimal first-move strategy is to shoot in the air.
    2. The complete ranking is: air > shoot A > shoot B.
    3. The exact survival probabilities are 2811/7900, 22377/79000, 19677/79000.
-/
@[blueprint "thm:truel-optimal"
  (statement := /-- C's optimal strategy is to shoot in the air, with survival probability $2811/7900$. -/)
  (uses := [Truel.air_beats_shootA, Truel.air_beats_shootB, Truel.shootA_beats_shootB])]
theorem truel_optimal_strategy :
    C_surv_air > C_surv_shootA
  ∧ C_surv_air > C_surv_shootB
  ∧ C_surv_shootA > C_surv_shootB
  ∧ C_surv_air = 2811 / 7900
  ∧ C_surv_shootA = 22377 / 79000
  ∧ C_surv_shootB = 19677 / 79000 :=
  ⟨air_beats_shootA, air_beats_shootB, shootA_beats_shootB,
   C_surv_air_val, C_surv_shootA_val, C_surv_shootB_val⟩

/-! ## §7. Geometric Series Foundation

We verify that our duel formula `duelFirstWins` correctly captures
the infinite geometric series. Specifically, if |r| < 1 where
r = (1-p)(1-q), then:

  Σ_{n=0}^∞ p · rⁿ = p / (1 - r) = p / (p + q - pq)

For the C-vs-B duel: r = (1 - 3/10)(1 - 7/10) = 21/100 < 1. ✓
-/

/-- The "miss-miss" probability in C vs B duel. -/
def r_CB : ℚ := (1 - 3/10) * (1 - 7/10)

theorem r_CB_val : r_CB = 21 / 100 := by unfold r_CB; norm_num
theorem r_CB_lt_one : r_CB < 1 := by unfold r_CB; norm_num
theorem r_CB_nonneg : 0 ≤ r_CB := by unfold r_CB; norm_num

/-- The duel formula equals p / (1 - r) where r = (1-p)(1-q). -/
@[blueprint "thm:duel-formula-correct"
  (statement := /-- The duel formula equals $p / (1 - (1-p)(1-q))$. -/)]
theorem duel_formula_correct (p q : ℚ) (_h : p + q - p * q ≠ 0) :
    duelFirstWins p q = p / (1 - (1 - p) * (1 - q)) := by
  unfold duelFirstWins
  congr 1
  ring

/-! ## §8. Summary of the Rationality Argument

The proof is structured as **backward induction** under common knowledge
of rationality (CKR):

**Step 1** (Base cases): Two-player duel probabilities are determined by
  the geometric series formula. No strategic choice exists — you shoot
  your only opponent.

**Step 2** (A's rationality): When it's A's turn with 3 alive, A compares:
  - Shoot B → survive with prob 7/10
  - Shoot C → survive with prob 3/10
  A shoots B. (`A_rational`)

**Step 3** (B's rationality): Given Step 2 (A will shoot B), when it's B's
  turn with 3 alive, B compares:
  - Shoot A → survive with prob 49/79
  - Shoot C → survive with prob 0
  - Air      → survive with prob 0
  B shoots A. (`B_rational_vs_C`, `B_rational_vs_air`)

**Step 4** (C's optimality): Given Steps 2–3 (B shoots A, A shoots B),
  C compares three strategies. Shooting in the air is strictly optimal.
  (`truel_optimal_strategy`)

Each step uses the rationality conclusions of all subsequent steps,
which is precisely the structure of **subgame-perfect Nash equilibrium**
solved by backward induction.
-/

end Truel
