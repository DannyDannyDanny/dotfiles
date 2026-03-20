# OpenClaw (AI assistant gateway) – Telegram, launchd, documents.
# Documents (SOUL.md, TOOLS.md, etc.) come from a separate repo via the flake input
# openclaw-documents (see flake.nix; override with e.g. github:you/openclaw-documents).
# Secrets (not in repo):
#   ~/.secrets/telegram-bot-token
#   ~/.secrets/openclaw-gateway-token   (one line, gateway auth token)
#   nixos/home/danny/openclaw-allow-from.nix  (gitignored; copy from .example)
# After editing, run: darwin-rebuild switch --flake . (from ~/dotfiles/nixos)

{ config, lib, pkgs, openclaw-documents, ... }:

let
  # Telegram user IDs from gitignored file so we don't commit them
  allowFromPath = ./. + "/openclaw-allow-from.nix";
  allowFrom = if builtins.pathExists allowFromPath then import allowFromPath else [ ];
in
{
  programs.openclaw = {
    enable = true;
    # Flake input: use .source (in-repo and separate-repo flakes expose source = ./.)
    documents = openclaw-documents.source or openclaw-documents.outPath or openclaw-documents;

    config = { };

    instances.default = {
      enable = true;
      config = {
        gateway = {
          mode = "local";
          auth.token = "";  # loaded from ~/.secrets/openclaw-gateway-token via wrapper
        };
        channels.telegram = {
          tokenFile = "/Users/danny/.secrets/telegram-bot-token";
          allowFrom = allowFrom;
          groups."*" = { requireMention = true; };
        };
      };
      plugins = [
        # e.g. { source = "github:openclaw/nix-steipete-tools?dir=tools/summarize"; }
      ];
    };
  };

  # Wrapper loads gateway token from file and execs the real gateway (keeps token out of store)
  home.file.".local/bin/openclaw-gateway-wrapper" = {
    source = ./openclaw-gateway-wrapper.sh;
    executable = true;
  };

  # TODO: Remove this bloat (see dotfiles TODO.md). Back up as target user so HM can overwrite.
  home.activation.backupOpenclawBeforeSwitch = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    OPENCLAW="${config.home.homeDirectory}/.openclaw"
    USER="${config.home.username}"
    if [ -d "$OPENCLAW" ]; then
      for f in "$OPENCLAW"/workspace/*.md "$OPENCLAW"/openclaw.json; do
        [ -e "$f" ] && [ ! -L "$f" ] && (sudo -u "$USER" mv -n "$f" "$f.backup" 2>/dev/null || true)
      done
    fi
  '';
  home.file.".openclaw/openclaw.json".force = true;

  # Override launchd agent to run wrapper so OPENCLAW_GATEWAY_TOKEN is set from file at runtime.
  # Do not reference config.launchd.agents."..." here (causes infinite recursion).
  launchd.agents."com.steipete.openclaw.gateway" = lib.mkForce {
    enable = true;
    config = {
      ProgramArguments = [
        (config.home.homeDirectory + "/.local/bin/openclaw-gateway-wrapper")
        "${pkgs.openclaw}/bin/openclaw"
        "gateway"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
