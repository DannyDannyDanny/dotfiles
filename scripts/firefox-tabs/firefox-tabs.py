#!/usr/bin/env python3
"""
Script to get information about Firefox's open tabs.
Works with Firefox installed via Nix/Home Manager.

Usage:
    python3 firefox-tabs.py [method] [rdp_port]
    
Methods:
    session, s  - Read from Firefox session files (default)
    rdp, r      - Use Remote Debugging Protocol
    both, b     - Try both methods
"""

import json
import sys
import os
import struct
import subprocess
from pathlib import Path
from urllib.request import urlopen
from urllib.error import URLError

# Try to find Nix Python with lz4 if available
def find_nix_python():
    """Try to find a Nix Python with lz4 library."""
    # Common Nix store paths
    nix_store = Path("/nix/store")
    if not nix_store.exists():
        return None
    
    # Look for Python with lz4 in the store
    # This is a heuristic - we look for python* directories that might have lz4
    try:
        result = subprocess.run(
            ["which", "python3"],
            capture_output=True,
            text=True
        )
        python_path = result.stdout.strip()
        if python_path and "/nix/store" in python_path:
            # Check if this Python has lz4
            result = subprocess.run(
                [python_path, "-c", "import lz4.frame; print('ok')"],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                return python_path
    except:
        pass
    
    return None

# Colors for output
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'  # No Color


def find_firefox_profile():
    """Find the default Firefox profile directory."""
    if sys.platform == "darwin":
        profile_dir = Path.home() / "Library/Application Support/Firefox"
    elif sys.platform.startswith("linux"):
        profile_dir = Path.home() / ".mozilla/firefox"
    else:
        print(f"{RED}Unsupported OS: {sys.platform}{NC}", file=sys.stderr)
        return None
    
    profiles_ini = profile_dir / "profiles.ini"
    
    if not profiles_ini.exists():
        print(f"{RED}Firefox profiles.ini not found at: {profiles_ini}{NC}", file=sys.stderr)
        print(f"{YELLOW}Make sure Firefox has been run at least once.{NC}", file=sys.stderr)
        return None
    
    # Find the default profile
    # Parse profiles.ini by sections
    profile_path = None
    current_section = None
    current_path = None
    is_default = False
    
    with open(profiles_ini, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('[') and line.endswith(']'):
                # Save previous section if it was default
                if is_default and current_path:
                    profile_path = current_path
                    break
                # Start new section
                current_section = line
                current_path = None
                is_default = False
            elif line.startswith("Path="):
                current_path = line.split("=", 1)[1].strip()
            elif line == "Default=1":
                is_default = True
    
    # Check if last section was default
    if is_default and current_path and not profile_path:
        profile_path = current_path
    
    # Fallback: get the first profile with Path=
    if not profile_path:
        with open(profiles_ini, 'r') as f:
            for line in f:
                if line.startswith("Path="):
                    profile_path = line.split("=", 1)[1].strip()
                    break
    
    if not profile_path:
        return None
    
    if Path(profile_path).is_absolute():
        return Path(profile_path)
    else:
        return profile_dir / profile_path


def decompress_lz4(file_path):
    """Decompress a Mozilla lz4 file and return the JSON content.
    
    Firefox uses a custom format:
    - 8 bytes: "mozLz40\0" header
    - 4 bytes: uncompressed size (little-endian uint32)
    - rest: lz4 frame compressed data
    """
    # Try Python lz4 library first (supports Mozilla format)
    # First try with current Python
    try:
        import lz4.block
        import struct
        with open(file_path, 'rb') as f:
            # Skip the 8-byte Mozilla header
            header = f.read(8)
            if header[:7] == b'mozLz40':
                # Read the 4-byte uncompressed size (little-endian uint32)
                size_bytes = f.read(4)
                if len(size_bytes) == 4:
                    uncompressed_size = struct.unpack('<I', size_bytes)[0]
                    # Read the rest (lz4 compressed data)
                    compressed_data = f.read()
                    # Try block decompression with the uncompressed size
                    try:
                        decompressed = lz4.block.decompress(compressed_data, uncompressed_size=uncompressed_size)
                        return decompressed.decode('utf-8')
                    except:
                        # Try without size hint
                        try:
                            decompressed = lz4.block.decompress(compressed_data)
                            return decompressed.decode('utf-8')
                        except:
                            # Try frame decompression as fallback
                            try:
                                import lz4.frame
                                decompressed = lz4.frame.decompress(compressed_data)
                                return decompressed.decode('utf-8')
                            except:
                                pass
                else:
                    return None
            else:
                # Try decompressing the whole file
                f.seek(0)
                compressed_data = f.read()
                try:
                    decompressed = lz4.block.decompress(compressed_data)
                    return decompressed.decode('utf-8')
                except:
                    import lz4.frame
                    decompressed = lz4.frame.decompress(compressed_data)
                    return decompressed.decode('utf-8')
    except ImportError:
        # Try to find and use Nix Python with lz4
        nix_python = find_nix_python()
        if nix_python:
            try:
                with open(file_path, 'rb') as f:
                    header = f.read(8)
                    if header[:7] == b'mozLz40':
                        compressed_data = f.read()
                    else:
                        f.seek(0)
                        compressed_data = f.read()
                
                # Use Nix Python to decompress
                result = subprocess.run(
                    [nix_python, "-c", f"""
import lz4.frame
import sys
with open('{file_path}', 'rb') as f:
    header = f.read(8)
    if header[:7] == b'mozLz40':
        data = f.read()
    else:
        f.seek(0)
        data = f.read()
    decompressed = lz4.frame.decompress(data)
    sys.stdout.buffer.write(decompressed)
"""],
                    capture_output=True,
                    check=True
                )
                return result.stdout.decode('utf-8')
            except Exception as e:
                print(f"{YELLOW}Nix Python lz4 error: {e}{NC}", file=sys.stderr)
        # Python lz4 library not available, try command-line tool
        pass
    except Exception as e:
        print(f"{YELLOW}Python lz4 library error: {e}, trying command-line tool...{NC}", file=sys.stderr)
    
    # Fallback to command-line lz4 (may not work with Mozilla format)
    try:
        with open(file_path, 'rb') as f:
            # Read and verify the Mozilla header (8 bytes: "mozLz40" + null byte)
            header = f.read(8)
            if header[:7] != b'mozLz40':
                print(f"{YELLOW}Warning: File doesn't have Mozilla lz4 header{NC}", file=sys.stderr)
                return None
            
            # Skip size bytes (4 bytes)
            f.read(4)
            
            # Read the rest of the file (lz4 frame compressed data)
            compressed_data = f.read()
            
            # Try command-line lz4 (may not work with Mozilla format)
            result = subprocess.run(
                ["lz4", "-dc"],
                input=compressed_data,
                capture_output=True,
                check=False
            )
            
            if result.returncode == 0:
                return result.stdout.decode('utf-8')
            else:
                print(f"{YELLOW}Command-line lz4 doesn't support Mozilla format.{NC}", file=sys.stderr)
                print(f"{YELLOW}To read session files, install Python lz4 library:{NC}", file=sys.stderr)
                print(f"{GREEN}  pip install lz4{NC}", file=sys.stderr)
                print(f"{YELLOW}Or use RDP method (see instructions when running 'python3 scripts/firefox-tabs.py rdp'):{NC}", file=sys.stderr)
                return None
    except subprocess.CalledProcessError as e:
        print(f"{YELLOW}Error decompressing {file_path}: {e}{NC}", file=sys.stderr)
        if e.stderr:
            print(f"{YELLOW}Error details: {e.stderr.decode()}{NC}", file=sys.stderr)
        return None
    except FileNotFoundError:
        print(f"{YELLOW}lz4 tool not found. Install it to read session files.{NC}", file=sys.stderr)
        if sys.platform == "darwin":
            print(f"{YELLOW}On macOS: brew install lz4{NC}", file=sys.stderr)
        else:
            print(f"{YELLOW}On NixOS: nix-env -iA nixpkgs.lz4{NC}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"{RED}Unexpected error: {e}{NC}", file=sys.stderr)
        return None


def get_tabs_from_session(profile_dir):
    """Extract tab information from Firefox session files."""
    profile_path = Path(profile_dir)
    session_file = profile_path / "sessionstore.jsonlz4"
    backup_dir = profile_path / "sessionstore-backups"
    
    # Try current session file
    if session_file.exists():
        print(f"{BLUE}Reading from current session...{NC}")
        content = decompress_lz4(session_file)
        if content:
            return parse_session_json(content)
    
    # Try backup files (including recovery.jsonlz4 which is updated while Firefox is running)
    if backup_dir.exists():
        # Check for recovery.jsonlz4 first (most recent when Firefox is running)
        recovery_file = backup_dir / "recovery.jsonlz4"
        if recovery_file.exists():
            print(f"{BLUE}Reading from recovery session (Firefox is running)...{NC}")
            content = decompress_lz4(recovery_file)
            if content:
                return parse_session_json(content)
        
        # Fallback to other backup files
        backup_files = sorted(backup_dir.glob("*.jsonlz4"), key=lambda p: p.stat().st_mtime, reverse=True)
        if backup_files:
            print(f"{BLUE}Reading from backup session...{NC}")
            content = decompress_lz4(backup_files[0])
            if content:
                return parse_session_json(content)
    
    print(f"{YELLOW}No session files found in profile directory{NC}", file=sys.stderr)
    return None


def parse_session_json(json_content):
    """Parse Firefox session JSON and extract tab information."""
    try:
        data = json.loads(json_content)
        windows = data.get('windows', [])
        
        tabs_info = []
        for window_idx, window in enumerate(windows):
            tabs = window.get('tabs', [])
            for tab_idx, tab in enumerate(tabs):
                entries = tab.get('entries', [])
                if entries:
                    # Last entry is usually the current one
                    current_entry = entries[-1]
                    url = current_entry.get('url', 'N/A')
                    title = current_entry.get('title', 'N/A')
                    tabs_info.append({
                        'window': window_idx + 1,
                        'tab': tab_idx + 1,
                        'title': title,
                        'url': url
                    })
        
        return tabs_info
    except json.JSONDecodeError as e:
        print(f"{RED}Error parsing session JSON: {e}{NC}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"{RED}Error processing session data: {e}{NC}", file=sys.stderr)
        return None


def is_firefox_running():
    """Check if Firefox is currently running."""
    try:
        if sys.platform == "darwin":
            result = subprocess.run(
                ["pgrep", "-f", "firefox|Firefox"],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        else:
            result = subprocess.run(
                ["pgrep", "firefox"],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
    except:
        return False


def get_tabs_via_rdp(port=6000):
    """Get tab information via Firefox Remote Debugging Protocol."""
    url = f"http://localhost:{port}/json/list"
    
    try:
        with urlopen(url, timeout=2) as response:
            data = json.loads(response.read())
            return data
    except URLError:
        print(f"{YELLOW}Firefox remote debugging not available on port {port}{NC}", file=sys.stderr)
        if is_firefox_running():
            print(f"{YELLOW}Firefox is running. To enable remote debugging:{NC}", file=sys.stderr)
            print(f"{GREEN}  1. Open Firefox and go to: about:config{NC}", file=sys.stderr)
            print(f"{GREEN}  2. Set these preferences:{NC}", file=sys.stderr)
            print(f"{GREEN}     - devtools.debugger.remote-enabled = true{NC}", file=sys.stderr)
            print(f"{GREEN}     - devtools.debugger.remote-port = {port}{NC}", file=sys.stderr)
            print(f"{GREEN}  3. Restart Firefox{NC}", file=sys.stderr)
        else:
            # Find Firefox binary
            firefox_bin = None
            try:
                if sys.platform == "darwin":
                    # Try to find Firefox in Nix store
                    result = subprocess.run(
                        ["find", "/nix/store", "-name", "firefox", "-type", "f", "-path", "*/MacOS/*"],
                        capture_output=True,
                        text=True,
                        timeout=5
                    )
                    if result.returncode == 0 and result.stdout.strip():
                        firefox_bin = result.stdout.strip().split('\n')[0]
            except:
                pass
            
            if firefox_bin:
                print(f"{YELLOW}To enable, start Firefox with:{NC}", file=sys.stderr)
                print(f"{GREEN}  {firefox_bin} --start-debugger-server={port}{NC}", file=sys.stderr)
            else:
                print(f"{YELLOW}To enable, start Firefox with:{NC}", file=sys.stderr)
                print(f"{GREEN}  firefox --start-debugger-server={port}{NC}", file=sys.stderr)
            print(f"{YELLOW}Or add to Firefox preferences (about:config):{NC}", file=sys.stderr)
            print(f"{GREEN}  devtools.debugger.remote-enabled = true{NC}", file=sys.stderr)
            print(f"{GREEN}  devtools.debugger.remote-port = {port}{NC}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"{RED}Error connecting to RDP: {e}{NC}", file=sys.stderr)
        return None


def print_tabs(tabs_info, method="session"):
    """Print tab information in a readable format."""
    if not tabs_info:
        return
    
    if method == "rdp":
        for tab in tabs_info:
            tab_id = tab.get('id', 'N/A')
            title = tab.get('title', 'N/A')
            url = tab.get('url', 'N/A')
            print(f"Tab {tab_id}: {title}")
            print(f"  URL: {url}")
    else:
        for tab in tabs_info:
            window = tab.get('window', '?')
            tab_num = tab.get('tab', '?')
            title = tab.get('title', 'N/A')
            url = tab.get('url', 'N/A')
            print(f"Window {window}, Tab {tab_num}: {title}")
            print(f"  URL: {url}")


def main():
    method = sys.argv[1] if len(sys.argv) > 1 else "session"
    rdp_port = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[1] in ["rdp", "r", "both", "b"] else 6000
    
    if method in ["session", "s"]:
        print(f"{GREEN}Getting tabs from session files...{NC}")
        profile_dir = find_firefox_profile()
        if profile_dir:
            tabs_info = get_tabs_from_session(profile_dir)
            if tabs_info:
                print_tabs(tabs_info, "session")
        else:
            sys.exit(1)
    
    elif method in ["rdp", "r"]:
        print(f"{GREEN}Fetching tabs via Remote Debugging Protocol...{NC}")
        tabs_info = get_tabs_via_rdp(rdp_port)
        if tabs_info:
            print_tabs(tabs_info, "rdp")
    
    elif method in ["both", "b"]:
        print(f"{GREEN}=== Session Files Method ==={NC}")
        profile_dir = find_firefox_profile()
        if profile_dir:
            tabs_info = get_tabs_from_session(profile_dir)
            if tabs_info:
                print_tabs(tabs_info, "session")
        
        print(f"\n{GREEN}=== Remote Debugging Protocol Method ==={NC}")
        tabs_info = get_tabs_via_rdp(rdp_port)
        if tabs_info:
            print_tabs(tabs_info, "rdp")
    
    else:
        print("Usage: python3 firefox-tabs.py [method] [rdp_port]")
        print("")
        print("Methods:")
        print("  session, s  - Read from Firefox session files (default)")
        print("  rdp, r      - Use Remote Debugging Protocol")
        print("  both, b     - Try both methods")
        print("")
        print("Examples:")
        print("  python3 firefox-tabs.py                    # Use session files (default)")
        print("  python3 firefox-tabs.py session            # Use session files")
        print("  python3 firefox-tabs.py rdp                # Use RDP on default port 6000")
        print("  python3 firefox-tabs.py rdp 9222           # Use RDP on port 9222")
        print("  python3 firefox-tabs.py both              # Try both methods")
        sys.exit(1)


if __name__ == "__main__":
    main()

