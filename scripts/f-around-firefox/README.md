# f-around-firefox (faf)

Get information about Firefox's open tabs from the command line.

## Usage

```bash
faf [method] [rdp_port]
```

**Methods:**
- `session`, `s` - Read from Firefox session files (default)
- `rdp`, `r` - Use Remote Debugging Protocol
- `both`, `b` - Try both methods

**Examples:**
```bash
faf                    # Use session files (default)
faf rdp                # Use RDP on default port 6000
faf rdp 9222           # Use RDP on port 9222
```

