# NixOS server quick-start

Get a new NixOS machine online as a server: hostname, user, SSH, and key-based login.

## 1. Prerequisites

- NixOS installed
- Machine on the network
- Console or existing SSH access

## 2. Hostname

In your config (e.g. `/etc/nixos/configuration.nix` or a flake module):

```nix
networking.hostName = "myserver";
```

## 3. User

Define a user in `users.users` (e.g. `danny` or `admin`). For key-only login you can leave the password empty or set a hashed one.

```nix
users.users.danny = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
  # Optional: hashed password, or omit for key-only login
  # hashedPassword = "...";  # mkpasswd -m sha-512
};
```

## 4. SSH

Enable OpenSSH and add your public keys so you can log in without a password.

```nix
services.openssh.enable = true;

users.users.danny.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... your-key-comment"
  # Add more keys (e.g. from ~/.ssh/id_*.pub on your client)
];
```

Optional hardening (disable password auth, restrict root):

```nix
services.openssh.settings = {
  PasswordAuthentication = false;
  PermitRootLogin = "no";
};
```

## 5. Apply and test

Rebuild and switch:

```bash
sudo nixos-rebuild switch
```

If you use a flake:

```bash
sudo nixos-rebuild switch --flake /path/to/dotfiles/nixos#hostname
```

From your main machine, test:

```bash
ssh danny@myserver
```

Replace `danny` and `myserver` with your user and hostname.
