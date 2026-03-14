# OpenClaw documents (separate repo)

SOUL.md, TOOLS.md, and any other markdown files used by OpenClaw are supplied via the flake input `openclaw-documents` in `nixos/flake.nix`. The input points at the **local clone** `path:/Users/danny/dotfiles/openclaw-documents-repo` so `sudo darwin-rebuild` doesn’t need SSH to GitHub. (Change the path in `flake.nix` if your clone lives elsewhere.)

## Repo contents

The repo (or local clone) must have at least:
- `SOUL.md` – who the assistant is, personality and boundaries
- `TOOLS.md` – what the assistant can use and how
- `AGENTS.md` – instructions for the AI when acting on your behalf  
  (The nix-openclaw module asserts these exist.)
- A minimal `flake.nix` so the repo can be used as a flake input:
  ```nix
  { outputs = { ... }: { source = ./.; }; }
  ```

## Local clone

The flake uses the local clone at `~/dotfiles/openclaw-documents-repo/` (path input, gitignored). Edit SOUL/TOOLS there; the next rebuild uses the current directory contents (no `nix flake update` needed). Push/pull to sync with the private GitHub repo when you like.

To use the remote repo instead (e.g. on another machine), set `openclaw-documents.url = "git+ssh://git@github.com/DannyDannyDanny/openclaw-documents"` in `nixos/flake.nix` and ensure your SSH key is loaded when running the rebuild.
