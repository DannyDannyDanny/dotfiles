"""Hara Gmail MCP server.

Exposes a small toolset for reading and writing mail across the configured
Gmail accounts.

Tools:
    list_accounts()                    list configured accounts
    list_inbox(email, limit)           recent messages from an account
    search(email, query, limit)        IMAP SEARCH wrapper
    read_email(email, uid)             full body of one message
    mark_read(email, uid)              mark a message as read
    archive(email, uid)                archive a message (remove from INBOX)
"""
from __future__ import annotations

import json
import logging
import os
import sys
from dataclasses import asdict

from mcp.server.fastmcp import FastMCP

from .accounts import AccountStore
from .imap_client import archive, list_inbox, mark_read, read_email, search

logger = logging.getLogger("hara_gmail_mcp")

mcp = FastMCP("hara-gmail-mcp")
_store: AccountStore | None = None


def _get_store() -> AccountStore:
    global _store
    if _store is None:
        _store = AccountStore.from_config_file()
    return _store


@mcp.tool()
def list_accounts() -> list[str]:
    """Return the email addresses of all Gmail accounts Hara can access."""
    return _get_store().emails()


@mcp.tool()
def gmail_list_inbox(email: str, limit: int = 20) -> str:
    """List the most recent messages in INBOX for the given account.

    Args:
        email: which configured account to read (use list_accounts to see options)
        limit: max number of messages to return, newest first (default 20, cap 100)

    Returns:
        JSON list of {uid, subject, sender, date, flags}.
    """
    limit = max(1, min(int(limit), 100))
    msgs = list_inbox(_get_store(), email, limit=limit)
    return json.dumps([asdict(m) for m in msgs], ensure_ascii=False)


@mcp.tool()
def gmail_search(email: str, query: str, limit: int = 20) -> str:
    """Run an IMAP SEARCH against the given account's INBOX.

    Args:
        email: which configured account to search
        query: raw IMAP search expression, e.g. 'UNSEEN', 'FROM alice@x.com',
            'SUBJECT "invoice"', 'SINCE 1-Jan-2026'. Quote arguments as needed.
        limit: max results (default 20, cap 100)

    Returns:
        JSON list of {uid, subject, sender, date, flags}.
    """
    limit = max(1, min(int(limit), 100))
    msgs = search(_get_store(), email, query=query, limit=limit)
    return json.dumps([asdict(m) for m in msgs], ensure_ascii=False)


@mcp.tool()
def gmail_read_email(email: str, uid: str) -> str:
    """Fetch the full body of one message by IMAP UID.

    Args:
        email: which configured account
        uid: the message UID (returned by gmail_list_inbox or gmail_search)

    Returns:
        JSON object with subject, sender, to, date, body_text, body_html, flags.
        BODY.PEEK is used so reading does not auto-mark the message as seen.
    """
    msg = read_email(_get_store(), email, uid=uid)
    return json.dumps(asdict(msg), ensure_ascii=False)


@mcp.tool()
def gmail_mark_read(email: str, uid: str) -> str:
    """Mark a message as read (sets the \\Seen flag).

    Args:
        email: which configured account
        uid: the message UID (returned by gmail_list_inbox or gmail_search)

    Returns:
        JSON object with ok and uid.
    """
    mark_read(_get_store(), email, uid=uid)
    return json.dumps({"ok": True, "uid": uid})


@mcp.tool()
def gmail_archive(email: str, uid: str) -> str:
    """Archive a message (copies to All Mail, removes from INBOX).

    Args:
        email: which configured account
        uid: the message UID (returned by gmail_list_inbox or gmail_search)

    Returns:
        JSON object with ok and uid.
    """
    archive(_get_store(), email, uid=uid)
    return json.dumps({"ok": True, "uid": uid})


def main() -> None:
    logging.basicConfig(
        level=os.environ.get("HARA_GMAIL_LOG_LEVEL", "INFO"),
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        stream=sys.stderr,
    )
    logger.info("hara-gmail-mcp starting")
    mcp.run()
