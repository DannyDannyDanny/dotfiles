# NixOS module for the Hara Gmail MCP server.
#
# Generates /etc/hara/gmail-accounts.json from declarative options and
# exposes the server binary through the dotfiles flake's pkgs set. Wiring
# the server into the claude-channels systemd service ExecStart is done
# by the host (phantom-ship.nix) so this module stays composable.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.hara-gmail-mcp;
  package = pkgs.callPackage ./. { };
  accountsJson = builtins.toJSON {
    accounts = map (a: {
      inherit (a) email password_file;
      imap_host = a.imapHost;
      imap_port = a.imapPort;
      smtp_host = a.smtpHost;
      smtp_port = a.smtpPort;
    }) cfg.accounts;
  };
in
{
  options.services.hara-gmail-mcp = {
    enable = lib.mkEnableOption "Hara Gmail MCP server (IMAP+SMTP)";

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      description = "The hara-gmail-mcp package to use.";
    };

    accounts = lib.mkOption {
      description = "Gmail accounts the MCP server should expose.";
      type = lib.types.listOf (lib.types.submodule {
        options = {
          email = lib.mkOption {
            type = lib.types.str;
            example = "user@example.com";
          };
          password_file = lib.mkOption {
            type = lib.types.path;
            description = "Path to the file containing the IMAP/SMTP app password.";
          };
          imapHost = lib.mkOption {
            type = lib.types.str;
            default = "imap.gmail.com";
          };
          imapPort = lib.mkOption {
            type = lib.types.port;
            default = 993;
          };
          smtpHost = lib.mkOption {
            type = lib.types.str;
            default = "smtp.gmail.com";
          };
          smtpPort = lib.mkOption {
            type = lib.types.port;
            default = 465;
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."hara/gmail-accounts.json" = {
      text = accountsJson;
      mode = "0644";
    };
  };
}
