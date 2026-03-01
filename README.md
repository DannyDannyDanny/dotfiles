# dotfiles

[nixos](https://nixos.org/) + [tmux](https://github.com/tmux/tmux) + [fish](https://fishshell.com/) + [neovim](https://neovim.io/)

Extension of [dannydannydanny/methodology](https://github.com/DannyDannyDanny/methodology).

## Roadmap

- [firefox-scrolling](firefox-scrolling.md) via terminal
- Server: [server](server.md); NixOS flake and bootstrap [nixos/readme.md](nixos/readme.md). SSH and secrets: [docs/ssh-and-secrets.md](docs/ssh-and-secrets.md).
- nvim checkhealth; tmux setup; [fonts](https://www.programmingfonts.org/) / nerdfonts; [HN: home server](https://news.ycombinator.com/item?id=34271167)

## Windows

- System sounds: None. Language/keyboard: en_US.
- [Powertoys](https://docs.microsoft.com/en-us/windows/powertoys/install) — remap CAPS to L-CTRL.
- [Alacritty](https://alacritty.org/) — config: `%AppData%/alacritty/alacritty.yml`.

### WSL

[Quickstart](https://github.com/nix-community/NixOS-WSL?tab=readme-ov-file#quick-start):

```bash
nix-shell -p gh git
gh auth login
gh repo clone dannydannydanny/dotfiles && cd dotfiles
# git checkout <branch>  # if needed
sudo nixos-rebuild switch --flake ~/dotfiles/nixos#wsl
```

### Clone via SSH

One key per purpose; see [AGENTS.md](AGENTS.md) and [docs/ssh-and-secrets.md](docs/ssh-and-secrets.md). Otherwise clone with HTTPS.

```bash
ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519_github <<<y
cat ~/.ssh/id_ed25519_github.pub   # add at https://github.com/settings/ssh/new
eval $(ssh-agent -s)   # fish: eval (ssh-agent -c)
ssh-add ~/.ssh/id_ed25519_github
git clone git@github.com:DannyDannyDanny/dotfiles.git && cd dotfiles
git config user.name "DannyDannyDanny"
git config user.email "dth@taiga.ai"
bash install.sh
```

## Good reads

- [TODOs aren't for doing](https://sophiebits.com/2025/07/21/todos-arent-for-doing)
