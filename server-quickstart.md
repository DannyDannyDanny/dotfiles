# NixOS server quick-start

Hostname, user, SSH, key-based login.

## 0. Installer choice

No Ethernet? Use the **graphical** ISO (`nixos-graphical-*-x86_64-linux.iso`). It has NetworkManager and a desktop—join Wi‑Fi in the GUI, then use a terminal. The minimal ISO has no GUI and Wi‑Fi on the live system is fiddly.

## 1. Prerequisites

NixOS installed, machine on the network, console or SSH.

## 2. Hostname

```nix
networking.hostName = "myserver";
```

## 3. User

```nix
users.users.danny = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
  # hashedPassword = "...";  # or omit for key-only
};
```

## 4. SSH

```nix
services.openssh.enable = true;

users.users.danny.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... your-key-comment"
];
```

To avoid committing keys (e.g. public repo): omit `openssh.authorizedKeys` and push keys via `scp ~/.ssh/*.pub danny@server:/tmp/` then on server: `cat /tmp/*.pub >> ~/.ssh/authorized_keys`.

Optional: `services.openssh.settings = { PasswordAuthentication = false; PermitRootLogin = "no"; };`

## 5. Apply and test

```bash
sudo nixos-rebuild switch
# or: sudo nixos-rebuild switch --flake /path/to/dotfiles#hostname
```

Then from your main machine: `ssh danny@myserver`
