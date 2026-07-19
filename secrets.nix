# Bridge so the agenix CLI works from the repo root.
# Paths inside are relative to secrets/, so still run `agenix` from secrets/
# for editing; this file exists for tooling that expects ./secrets.nix.
import ./secrets/secrets.nix
