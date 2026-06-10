import Lake
open Lake DSL

package ns_tower

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.12.0"

require opera_sieve from git
  "https://github.com/DavidFox998/opera-sieve" @ "v1.1.0-bost-connes"

@[default_target]
lean_lib NSTower where
  globs := #[.submodule `Towers, .submodule `Foundations]
