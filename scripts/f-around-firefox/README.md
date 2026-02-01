# f-around-firefox (faf)

Get information about Firefox's open tabs from the command line.

## Usage

```bash
faf [method] [rdp_port]
faf content <tab-id> [rdp_port]
```

**Methods:**
- `session`, `s` - Read from Firefox session files (default)
- `rdp`, `r` - Use Remote Debugging Protocol
- `both`, `b` - Try both methods
- `content`, `c` - Get HTML content from a tab via WebSocket

**Examples:**
```bash
faf                    # Use session files (default)
faf rdp                # Use RDP on default port 6000
faf rdp 9222           # Use RDP on port 9222
faf content 123        # Get HTML from tab 123 (port 6000)
faf content 123 9222   # Get HTML from tab 123 (port 9222)
```

## Content Command

The `content` command connects to a Firefox tab via WebSocket using the Remote Debugging Protocol and retrieves the rendered HTML content. This enables agentic workflows where you can query webpages you have open in Firefox.

**Requirements:**
- Firefox must be running with remote debugging enabled
- The tab must be debuggable (most regular web pages are, but `about:` pages may not be)
- The `websockets` Python library must be available

**Output:**
The command outputs raw HTML to stdout, making it easy to pipe to other tools:
```bash
faf content 123 | grep "some-text"
faf content 123 > page.html
```

## Troubleshooting

### HTTP Endpoint Not Responding

If you see "Remote end closed connection without response" errors even though Firefox shows DevTools is connected (indicated by the browser being "under remote control" in the address bar), this is a known issue that needs investigation. The WebSocket connections may work even when the HTTP `/json/list` endpoint doesn't respond properly.

**Workaround:** Try using the `content` command directly if you know the tab ID, or use the session file method to list tabs.

### Running from Nix Development Shell

If the `websockets` library is not available in your system Python, you can run the script from the Nix development shell:

```bash
cd scripts/f-around-firefox
nix develop -c $(which fish)
python3 faf.py rdp
# or
python3 faf.py content <tab-id>
```

**Note:** Use `nix develop -c $(which fish)` to properly enter the shell with fish. This ensures the script has access to all required dependencies including `websockets` and `lz4`.

