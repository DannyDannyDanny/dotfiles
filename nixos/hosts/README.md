# Hosts

Per-host NixOS configs for the homelab and admin Mac. Each `<host>.nix`
declares the host's role and services; the `<host>-hardware.nix` siblings
(where present) describe disks, kernel modules, firmware. Bootstrap +
disko configs live one level up in `../`.

## Topology

```
                              ┌────────────────────────────────────────────┐
                              │  vps-relay  (Hetzner, public IP, ZT peer)  │
public traffic ──TLS:443──────│  Caddy + Let's Encrypt → reverse_proxy     │
                              │  over ZeroTier to a clan backend           │
                              └──────────────────┬─────────────────────────┘
                                                 │ (ZeroTier mesh)
                                                 │
              ┌──────────────────────┬───────────┴───────────┬──────────────────────┐
              │                      │                       │                      │
        sunken-ship             phantom-ship           distant-shore           foreign-port
        (LAN, wifi)             (LAN, wired)           (LAN, wifi)             (LAN, wifi)
        ZT controller           NAT for                blank slate             blank slate
        media + mulbo           rusty-anchor           (room to grow)          (room to grow)
                                services hub

  ── outside the clan ──────────────────────────────────────────────────────────────────────
        Daniel-Macbook-Air                                        rusty-anchor
        (admin, runs clan-cli)                                    (downstream of phantom-ship's NAT)
```

ZeroTier IPv6 addresses for the four clan machines are declared in
`../../flake-modules/clan.nix` (`sunkenShipZTv6` / `phantomShipZTv6` /
`vpsRelayZTv6` / etc.). They land in every host's `/etc/hosts` as
`<machine>.clan` so data-mesher and ad-hoc SSH can resolve over the mesh.

---

## Hosts

### sunken-ship  ·  media + ZT controller

- **Hardware:** see `sunken-ship-hardware.nix`. WiFi-only, no LUKS (boots
  unattended).
- **Network:** LAN over WiFi, on the ZT mesh as the **controller** (manages
  ZT membership for the whole fleet). ZT IPv6 is the clan's "internet"
  target for `clan machines update`.
- **Role:** media + the long-running personal services that don't fit on
  phantom-ship.
- **Current services:** `navidrome` (subsonic API, `/srv/music`), `uxplay`
  (AirPlay receiver), `mulbo-server` (+ `-pull` / `-backfill` / `-enrich`
  timers), `fitness-bot` (+ `-pull` / `-shipyard` variants),
  `dm-pull-deploy-push` (announces origin/main rev to the mesh every 15 m).

### phantom-ship  ·  services hub + LAN NAT

- **Hardware:** see `phantom-ship-hardware.nix`. WiFi for WAN, wired
  ethernet (`enp0s31f6`) serves the lab subnet (NAT + dnsmasq for
  `rusty-anchor`).
- **Network:** LAN over WiFi, on the ZT mesh. Backends are exposed only on
  the ZT interface (`firewall.interfaces."zt+".allowedTCPPorts = [ … ]`)
  so vps-relay's Caddy can reach them. WAN side stays closed.
- **Role:** where new self-hosted apps default to going. Hosts a growing
  list of mini-app backends + a couple of long-running daemons.
- **Current services:** `forgejo` (`git.dannydannydanny.me`),
  `claude-channels` (Telegram bridge for `@HarakatBot`),
  `hara-gmail-mcp` + `hara-heartbeat` (timer),
  Mini-App backends (`shelfish`, `scuttle`, `bananasimulator`,
  `komtolk`, `escape-hormuz`, `bon`), `ollama` (local LLM), `shipyard`,
  `dnsmasq` (lab subnet DHCP/DNS). `openclaw-gateway` is disabled —
  superseded by `claude-channels` but kept for easy rollback.

### vps-relay  ·  public reverse proxy

- **Hardware:** Hetzner Cloud vServer (BIOS-boot, virtio). Disk via
  `../disko-cloud.nix`.
- **Network:** public IP `89.167.39.251`. Inbound: SSH/22, HTTP/80,
  HTTPS/443 only. fail2ban guards SSH. Outbound to clan backends over ZT.
- **Role:** terminates public TLS, reverse-proxies subdomains over ZT to
  whichever clan host runs the backend. **No application data ever lands
  here** — this box is a relay. New public app = add a `virtualHosts`
  entry + a GoDaddy A record pointing at `89.167.39.251`.
- **Current vhosts:** `navidrome.`, `bbbot.`, `shelfish.`, `scuttle.`,
  `bananasimulator.`, `komtolk.`, `git.`, `escapehormuz.`, etc.

### distant-shore  ·  ThinkPad X13 Gen 2, blank slate

- **Hardware:** see `distant-shore-hardware.nix`. Intel i5-1145G7, 16 GB.
  WiFi-only, headless, no LUKS. Secure-Boot-chained boot (shim + MOK,
  see comments in `distant-shore.nix`).
- **Network:** LAN over WiFi, on the ZT mesh.
- **Role:** _to be assigned_. In the clan inventory; auto-rebuilds via
  dm-pull-deploy. Drop a service in to give it a purpose.

### foreign-port  ·  laptop, blank slate (WIP)

- **Hardware:** see `foreign-port-hardware.nix`. WiFi-only, headless,
  no LUKS. Vendor-signed-shim boot chain.
- **Status:** still being wired up — not in the clan inventory yet.
- **Role:** _to be assigned_, same flow as `distant-shore`.

### daniel-macbook-air  ·  admin

- **Hardware:** MacBook Air (the daily driver).
- **Role:** outside the clan. Runs `clan machines update` to push to
  the servers + holds the SSH keys that authorize root@ on each clan
  host. Also a ZT peer.

### wsl

- **Role:** WSL development environment (legacy / occasional).

---

## Deployment

### Automatic (the default)

`dm-pull-deploy` (clan-community module wired in `clan.nix`):

1. **Push announcement:** sunken-ship's `dm-pull-deploy-push` timer runs
   `dm-send-deploy` every 15 m. It signs and broadcasts the current
   `origin/main` rev over the data-mesher gossip protocol.
2. **Pull + rebuild:** each `roles.default` machine (currently
   `sunken-ship`, `phantom-ship`) runs a `.path` watcher that fires when
   the gossiped rev changes; it `git fetch`es and `nixos-rebuild switch`es.

So **a push to `origin/main` rolls out within ~15 m** on the two
production hosts. No SSH-from-Mac required.

`vps-relay` and `distant-shore` are **not** in `roles.default` — they
need a manual deploy (see below) until/unless their role changes.

### Manual

From `~/dotfiles` on the Mac:

```
nix run 'git+https://git.clan.lol/clan/clan-core#clan-cli' -- \
  machines update <host>
```

Caveats encountered in practice:

- The Mac's `ssh-agent` often has the wrong key loaded for clan deploys.
  Prefix with `env -u SSH_AUTH_SOCK` to force `~/.ssh/config` identity
  selection.
- A nixpkgs bump may register a new generation but refuse to live-switch
  due to "switch inhibitors". Add `--no-check` to force.
- `vps-relay` only accepts `~/.ssh/id_ed25519_sunken_ship` (the Mac's
  copy of sunken-ship's authorized key). The agent's other keys won't
  open it.

Putting both together:

```
env -u SSH_AUTH_SOCK nix run 'git+https://git.clan.lol/clan/clan-core#clan-cli' \
  -- machines update phantom-ship --no-check
```

### From sunken-ship

`vps-relay` was originally only reachable from sunken-ship's SSH key.
That still works as a fallback — SSH to sunken-ship and run the same
`nix run … -- machines update vps-relay` command from `/etc/dotfiles`
there. The dotfiles checkout at `/etc/dotfiles` is maintained by
dm-pull-deploy.

---

## Public traffic pattern

```
user → DNS *.dannydannydanny.me → 89.167.39.251 (vps-relay)
     → Caddy (Let's Encrypt, ports 80/443)
     → reverse_proxy http://[<backend ZT IPv6>]:<port>
     → service on sunken-ship or phantom-ship
```

To add a new public app:

1. Add a `virtualHosts` entry to `vps-relay.nix` pointing at the
   backend's ZT IPv6 and port.
2. Add the GoDaddy A record `<sub>.dannydannydanny.me → 89.167.39.251`.
3. Run the backend on the chosen host. Either:
   - bind to `127.0.0.1:<port>` (if backend + Caddy are co-resident — not
     the case here), **or**
   - bind to `0.0.0.0` (or `::`) and add the port to
     `networking.firewall.interfaces."zt+".allowedTCPPorts` on the
     backend host so only the ZT interface accepts inbound.
4. Push dotfiles. Production hosts auto-rebuild via dm-pull-deploy.
   vps-relay needs a manual `clan machines update vps-relay`.

---

## SSH keys (quick reference)

- **`~/.ssh/id_ed25519_phantom_ship`** (Mac) — authorized as `danny@` and
  `root@` on phantom-ship.
- **`~/.ssh/id_ed25519_sunken_ship`** (Mac) — authorized as `danny@` (and
  via root mirror) on sunken-ship; also the authorized key on `vps-relay`.
- **sunken-ship `~/.ssh/id_ed25519`** — sunken-ship's own key; used by
  cluster-internal ops (mulbo-pull, dm-send-deploy, fallback path for
  vps-relay deploys).
- **`~/.ssh/id_ed25519_github`** (Mac) — GitHub auth, not clan.

Authorized-keys lists live in each host's `users.users.{danny,root}.openssh.authorizedKeys.keys`.
