"""Account config loader.

Reads a JSON file (default: /etc/hara/gmail-accounts.json) listing the Gmail
accounts Hara can act on, and the path to each account's IMAP/SMTP app
password. Passwords are loaded once via `sudo -n cat` because the password
files are root:991 0640 and the MCP server process runs as `danny`. The
result is cached in memory for the process lifetime.

Schema:
    {
      "accounts": [
        {
          "email": "user@example.com",
          "password_file": "/etc/openclaw/gmail-user-app-password",
          "imap_host": "imap.gmail.com",
          "imap_port": 993,
          "smtp_host": "smtp.gmail.com",
          "smtp_port": 465
        }
      ]
    }
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path

DEFAULT_CONFIG_PATH = "/etc/hara/gmail-accounts.json"
# NixOS keeps the setuid sudo wrapper at /run/wrappers/bin; non-NixOS distros
# put it in /usr/bin or /bin. We try $PATH first, then fall back to these.
_SUDO_FALLBACKS = ["/run/wrappers/bin/sudo", "/usr/bin/sudo", "/bin/sudo"]


def _find_sudo() -> str:
    found = shutil.which("sudo")
    if found:
        return found
    for candidate in _SUDO_FALLBACKS:
        if Path(candidate).exists():
            return candidate
    raise RuntimeError(
        "sudo not found on PATH or in known locations; "
        "cannot read group-restricted password files"
    )


@dataclass(frozen=True)
class Account:
    email: str
    password_file: str
    imap_host: str
    imap_port: int
    smtp_host: str
    smtp_port: int


class AccountStore:
    """Holds account metadata and lazily resolves passwords on first use."""

    def __init__(self, accounts: list[Account]) -> None:
        self._accounts = {a.email: a for a in accounts}
        self._password_cache: dict[str, str] = {}

    @classmethod
    def from_config_file(cls, path: str | os.PathLike[str] | None = None) -> "AccountStore":
        config_path = Path(path or os.environ.get("HARA_GMAIL_CONFIG", DEFAULT_CONFIG_PATH))
        with config_path.open() as f:
            data = json.load(f)
        accounts = [
            Account(
                email=a["email"],
                password_file=a["password_file"],
                imap_host=a.get("imap_host", "imap.gmail.com"),
                imap_port=int(a.get("imap_port", 993)),
                smtp_host=a.get("smtp_host", "smtp.gmail.com"),
                smtp_port=int(a.get("smtp_port", 465)),
            )
            for a in data.get("accounts", [])
        ]
        return cls(accounts)

    def emails(self) -> list[str]:
        return list(self._accounts.keys())

    def get(self, email: str) -> Account:
        try:
            return self._accounts[email]
        except KeyError:
            raise ValueError(f"Unknown account: {email!r}. Configured: {self.emails()}")

    def password_for(self, email: str) -> str:
        if email in self._password_cache:
            return self._password_cache[email]
        account = self.get(email)
        # Prefer direct read if the file is reachable (e.g. after path 2
        # migration where the daemon owns its own creds), fall back to
        # `sudo -n cat` for the current /etc/openclaw/ layout.
        try:
            value = Path(account.password_file).read_text().strip()
        except PermissionError:
            value = subprocess.check_output(
                [_find_sudo(), "-n", "cat", account.password_file],
                text=True,
            ).strip()
        if not value:
            raise RuntimeError(f"Empty password file for {email}: {account.password_file}")
        self._password_cache[email] = value
        return value
