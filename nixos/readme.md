Rebuild nixos and points to dotfiles dir:

```
sudo nixos-rebuild switch --flake ~/dotfiles/nixos#macbookair
# or
sudo nixos-rebuild switch --flake ~/dotfiles/nixos#wsl
# or
sudo -H nix run github:lnl7/nix-darwin -- switch --flake ~/dotfiles/nixos#Daniel-Macbook-Air
```

