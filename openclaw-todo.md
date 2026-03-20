# OpenClaw Setup TODO

## Current state

OpenClaw is **already fully wired** into the macOS (Daniel-Macbook-Air) darwin config:

- **Keep:** `nix-openclaw` flake input, overlay, home-manager module import — all correct
- **Keep:** `nixos/home/danny/openclaw.nix` — working config with launchd agent, wrapper, documents integration
- **Keep:** `openclaw-gateway-wrapper.sh` — loads gateway token from `~/.secrets/` at runtime
- **Keep:** `openclaw-allow-from.nix` (gitignored) — Telegram user ID allowlist
- **Scrap/fix:** `home.activation.backupOpenclawBeforeSwitch` — marked as bloat in a TODO; remove once confirmed unnecessary
- **Not wired:** `sunken-ship` and `macbookair` NixOS configs have zero OpenClaw references

## Phase 1: Get OpenClaw running on macOS (Daniel-Macbook-Air)

- [ ] Ensure `openclaw-documents-repo` exists at `~/dotfiles/openclaw-documents-repo` (or clone it)
- [ ] Create secrets:
  - `~/.secrets/telegram-bot-token` (from @BotFather)
  - `~/.secrets/openclaw-gateway-token` (gateway auth token)
- [ ] Copy `openclaw-allow-from.nix.example` → `openclaw-allow-from.nix`, fill in Telegram user ID(s)
- [ ] Rebuild: `cd ~/dotfiles/nixos && darwin-rebuild switch --flake .`
- [ ] Verify launchd agent: `launchctl list | grep openclaw`
- [ ] Test: message bot on Telegram
- [ ] Verify Ollama integration: `ollama list` (already enabled via `macos.nix` → `ollama.nix`)

## Phase 2: Move to dedicated server (sunken-ship or new host)

- [ ] **Decide:** run OpenClaw on sunken-ship (existing) or a new host (phantom-ship)?
- [ ] Add `nix-openclaw` + `openclaw-documents` to the NixOS config's `specialArgs` (currently only passed to darwinConfigurations)
- [ ] Port `openclaw.nix` from home-manager launchd agent → systemd user service (or system service)
  - Replace `launchd.agents` block with `systemd.user.services` equivalent
  - Update wrapper to use systemd `EnvironmentFile=` instead of bash wrapper
- [ ] Handle secrets on server:
  - `scp` token files to server `~/.secrets/` (don't commit)
  - Or use `agenix`/`sops-nix` for encrypted secrets in repo
- [ ] Decide on documents: clone `openclaw-documents-repo` on server, or use GitHub flake input instead of local path
- [ ] If Ollama needed on server: port `ollama.nix` (launchd → systemd) or use nixpkgs `services.ollama` (available in NixOS, not nix-darwin)
- [ ] Rebuild on server: `sudo nixos-rebuild switch --flake .#sunken-ship`

## Packaging decisions

| Decision | Current | Options |
|---|---|---|
| OpenClaw binary | `nix-openclaw` flake input | **Keep** — gives overlay + HM module |
| Documents | Local path flake input | Local path for dev, switch to `github:` for server |
| Ollama on macOS | Custom `ollama.nix` (PR #972) | **Keep** until nix-darwin merges upstream |
| Ollama on NixOS | Not configured | Use `services.ollama` from nixpkgs (built-in on NixOS) |
| Secrets | Files in `~/.secrets/` | Fine for now; consider `sops-nix` if adding more |
