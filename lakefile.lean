import Lake
open Lake DSL

package «Truel»

require LeanArchitect from git
  "https://github.com/hanwenzhu/LeanArchitect.git" @ "main"

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "v4.30.0-rc1"

@[default_target]
lean_lib «Truel» where
  roots := #[`Truel]
