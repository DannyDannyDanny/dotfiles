Rebuild nixos and points to dotfiles dir:

```
sudo nixos-rebuild switch --flake ~/dotfiles/nixos
```

Overwrite wsl `resolv.conf`:

```
cp ~/dotfiles/nixos/resolv.conf /etc/
```
