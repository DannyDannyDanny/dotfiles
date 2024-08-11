{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    configure = {
      # colorscheme blue
      # colorscheme desert
      customRC = ''
        colorscheme peachpuff
	set listchars=tab:→\ ,space:·,nbsp:␣,trail:•,eol:¶,precedes:«,extends:»
      '';
    };
  };
}
 
