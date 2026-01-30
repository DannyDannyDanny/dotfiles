# Firefox Tabs Script

Get information about Firefox's open tabs from the command line.

## Usage

```bash
python3 firefox-tabs.py [method] [rdp_port]
```

**Methods:**
- `session`, `s` - Read from Firefox session files (default)
- `rdp`, `r` - Use Remote Debugging Protocol
- `both`, `b` - Try both methods

**Examples:**
```bash
python3 firefox-tabs.py                    # Use session files (default)
python3 firefox-tabs.py rdp               # Use RDP on default port 6000
python3 firefox-tabs.py rdp 9222          # Use RDP on port 9222
```

## Setup

### Using Nix (Recommended)

```bash
cd scripts/firefox-tabs
nix develop
python3 firefox-tabs.py
```

### Manual Setup

Install Python lz4 library:
```bash
pip install lz4
```

## Remote Debugging Protocol

To use RDP method, enable remote debugging in Firefox:

1. Open Firefox and go to `about:config`
2. Set these preferences:
   - `devtools.debugger.remote-enabled` = `true`
   - `devtools.debugger.remote-port` = `6000`
3. Restart Firefox

## Requirements

- Python 3
- `lz4` Python library (for session file method)
- Firefox installed and run at least once

