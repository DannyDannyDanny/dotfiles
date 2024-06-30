# article / guide:
# https://taoa.io/posts/Setting-up-ipad-screen-mirroring-on-nixos
# https://gist.github.com/cmrfrd/fe8f61da076f8a4a751bf8fc8cb579a5
# also see: 24_nix_uxplay for script

{ config, pkgs, ... }:

{
  services.avahi = {
    nssmdns = true;
    enable = true;
    publish = {
      enable = true;
      userServices = true;
      domain = true;
    };
  };
}
