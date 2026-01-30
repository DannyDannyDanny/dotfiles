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

