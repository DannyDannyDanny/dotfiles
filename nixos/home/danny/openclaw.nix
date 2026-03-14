# OpenClaw (AI assistant gateway) – Telegram, launchd, documents.
# Secrets (not in repo):
#   ~/.secrets/telegram-bot-token
#   ~/.secrets/openclaw-gateway-token   (one line, gateway auth token)
#   nixos/home/danny/openclaw-allow-from.nix  (gitignored; copy from .example)
# After editing, run: darwin-rebuild switch --flake . (from ~/dotfiles/nixos)

{ config, lib, ... }:

let
  # Telegram user IDs from gitignored file so we don't commit them
  allowFromPath = ./. + "/openclaw-allow-from.nix";
  allowFrom = if builtins.pathExists allowFromPath then import allowFromPath else [ ];
in
{
  programs.openclaw = {
    enable = true;
    documents = ./openclaw-documents;

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

  # Prepend wrapper to launchd so OPENCLAW_GATEWAY_TOKEN is set from file at runtime
  launchd.agents."com.steipete.openclaw.gateway" = lib.mkForce (
    (config.launchd.agents."com.steipete.openclaw.gateway" or { }) // {
      config = (config.launchd.agents."com.steipete.openclaw.gateway".config or { }) // {
        ProgramArguments = [
          (config.home.homeDirectory + "/.local/bin/openclaw-gateway-wrapper")
        ] ++ (config.launchd.agents."com.steipete.openclaw.gateway".config.ProgramArguments or [ ]);
      };
    }
  );
}
