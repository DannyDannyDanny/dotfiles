# Sunken-ship WiFi

WiFi is enabled via [networking.wireless](../nixos/hosts/sunken-ship.nix) with **no networks** in Nix. The NixOS service uses **`/etc/wpa_supplicant/imperative.conf`** (not `/etc/wpa_supplicant.conf`). SSID and PSK stay out of the repo.

## Create the config on the server

The daemon reads **`/etc/wpa_supplicant/imperative.conf`**. Put only the `network={}` block there — do **not** add `ctrl_interface` (the service manages that and will fail if you set it).

**Option A — write directly to imperative.conf:**

```bash
sudo tee /etc/wpa_supplicant/imperative.conf << 'EOF'
network={
    ssid="YOUR_SSID"
    psk="YOUR_PASSWORD"
}
EOF
sudo chown wpa_supplicant:wpa_supplicant /etc/wpa_supplicant/imperative.conf
sudo chmod 664 /etc/wpa_supplicant/imperative.conf
sudo systemctl restart wpa_supplicant
```

**Option B — use /etc/wpa_supplicant.conf then copy only the network block:**

```bash
# 1) Create /etc/wpa_supplicant.conf with your network{} block (and optional ctrl_interface lines if you use wpa_cli elsewhere).
sudo nano /etc/wpa_supplicant.conf   # or tee as above

# 2) Copy only the network block into imperative.conf (strip ctrl_interface so the service doesn't fail).
sudo sed '/^ctrl_interface/d;/^ctrl_interface_group/d;/^update_config/d' /etc/wpa_supplicant.conf | sudo tee /etc/wpa_supplicant/imperative.conf > /dev/null
sudo chown wpa_supplicant:wpa_supplicant /etc/wpa_supplicant/imperative.conf
sudo chmod 664 /etc/wpa_supplicant/imperative.conf
sudo systemctl restart wpa_supplicant
```

Or generate the `network{}` block with a hashed PSK (optional):

```bash
nix shell nixpkgs#wpa_supplicant -c wpa_passphrase "YOUR_SSID" "YOUR_PASSWORD"
# Use the network={...} part in imperative.conf.
```

## Rebuild (after changing Nix config)

From the server (flake is at the repo root):

```bash
cd /etc/dotfiles && sudo nixos-rebuild switch --flake .#sunken-ship
```

## Verify

- Service: `systemctl status wpa_supplicant`
- Interface and IP: `ip addr show wlp5s0` — should get an address when associated.
- Connectivity: `ping -c 2 8.8.8.8` or unplug ethernet and confirm you still have connectivity.
- Optional (if ctrl_interface is in config):  
  `nix shell nixpkgs#wpa_supplicant -c wpa_cli -i wlp5s0 status`  
  Expect `wpa_state=COMPLETED` and your `ssid=` when connected.
