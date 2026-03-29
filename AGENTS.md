# AGENTS.md — tyler_config

Read the shared guidelines first:
- [General](../general_documentation/Agentic_Coding/AGENTS.md)

This file adds only tyler_config-specific overrides.

## Public Repo Policy
- This is a public GitHub repo. Do not add secrets, and avoid
  over-exposing sensitive local details.

## Repo Layout
- The repo exists to keep config files from various machines in
  version control.
- When you reference files like `.zshrc`, prefer the repo copy
  instead of inspecting the local machine outside this repo unless
  explicitly asked.
- `homedir/` is a replacement for `~`.
- Any other directory in this repo should mirror the exact path
  layout from the local machine.
