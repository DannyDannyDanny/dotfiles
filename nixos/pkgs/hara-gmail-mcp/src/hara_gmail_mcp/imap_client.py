"""Minimal IMAP wrapper over stdlib imaplib.

One short-lived IMAP connection per call. Good enough for v1; if latency
hurts when Hara fans out across three accounts in a summary, swap to a
connection pool keyed by account email.
"""
from __future__ import annotations

import email
import email.policy
import imaplib
from contextlib import contextmanager
from dataclasses import dataclass, field
from email.message import EmailMessage
from typing import Iterator

from .accounts import Account, AccountStore


@dataclass
class MessageSummary:
    uid: str
    subject: str
    sender: str
    date: str
    snippet: str = ""
    flags: list[str] = field(default_factory=list)


@dataclass
class FullMessage:
    uid: str
    subject: str
    sender: str
    to: str
    date: str
    body_text: str
    body_html: str
    flags: list[str] = field(default_factory=list)


@contextmanager
def _open(account: Account, password: str, mailbox: str = "INBOX") -> Iterator[imaplib.IMAP4_SSL]:
    conn = imaplib.IMAP4_SSL(account.imap_host, account.imap_port)
    try:
        conn.login(account.email, password)
        # SELECT for read-write, EXAMINE for read-only. Use SELECT so we can
        # add/remove flags later (label/archive). Most reads still tolerate
        # the implicit \Seen behaviour Gmail applies; we set PEEK below.
        typ, _ = conn.select(mailbox)
        if typ != "OK":
            raise RuntimeError(f"SELECT {mailbox} failed for {account.email}")
        yield conn
    finally:
        try:
            conn.logout()
        except Exception:
            pass


def _decode_header(raw: str | None) -> str:
    if not raw:
        return ""
    parts = email.header.decode_header(raw)
    out = []
    for chunk, enc in parts:
        if isinstance(chunk, bytes):
            try:
                out.append(chunk.decode(enc or "utf-8", errors="replace"))
            except LookupError:
                out.append(chunk.decode("utf-8", errors="replace"))
        else:
            out.append(chunk)
    return "".join(out)


def list_inbox(
    store: AccountStore,
    email_addr: str,
    limit: int = 20,
    mailbox: str = "INBOX",
) -> list[MessageSummary]:
    account = store.get(email_addr)
    password = store.password_for(email_addr)
    with _open(account, password, mailbox) as conn:
        typ, data = conn.uid("search", None, "ALL")
        if typ != "OK":
            raise RuntimeError(f"SEARCH ALL failed for {email_addr}")
        uids = data[0].split()[-limit:][::-1]  # most recent first
        return [_fetch_summary(conn, uid.decode()) for uid in uids]


def search(
    store: AccountStore,
    email_addr: str,
    query: str,
    limit: int = 20,
    mailbox: str = "INBOX",
) -> list[MessageSummary]:
    """Run an IMAP SEARCH. `query` is a raw IMAP search expression, e.g.
    `FROM alice@example.com`, `UNSEEN`, `SUBJECT "invoice"`, `SINCE 1-Jan-2026`.
    """
    account = store.get(email_addr)
    password = store.password_for(email_addr)
    with _open(account, password, mailbox) as conn:
        typ, data = conn.uid("search", None, query)
        if typ != "OK":
            raise RuntimeError(f"SEARCH {query!r} failed for {email_addr}")
        uids = data[0].split()[-limit:][::-1]
        return [_fetch_summary(conn, uid.decode()) for uid in uids]


def read_email(
    store: AccountStore,
    email_addr: str,
    uid: str,
    mailbox: str = "INBOX",
) -> FullMessage:
    account = store.get(email_addr)
    password = store.password_for(email_addr)
    with _open(account, password, mailbox) as conn:
        # BODY.PEEK[] avoids setting \Seen automatically.
        typ, data = conn.uid("fetch", uid, "(FLAGS BODY.PEEK[])")
        if typ != "OK" or not data or data[0] is None:
            raise RuntimeError(f"FETCH uid={uid} failed for {email_addr}")
        meta, raw = data[0]
        flags = _parse_flags(meta.decode() if isinstance(meta, bytes) else meta)
        msg: EmailMessage = email.message_from_bytes(raw, policy=email.policy.default)
        body_text = ""
        body_html = ""
        if msg.is_multipart():
            for part in msg.walk():
                ctype = part.get_content_type()
                if ctype == "text/plain" and not body_text:
                    body_text = part.get_content()
                elif ctype == "text/html" and not body_html:
                    body_html = part.get_content()
        else:
            ctype = msg.get_content_type()
            if ctype == "text/html":
                body_html = msg.get_content()
            else:
                body_text = msg.get_content()
        return FullMessage(
            uid=uid,
            subject=_decode_header(msg["Subject"]),
            sender=_decode_header(msg["From"]),
            to=_decode_header(msg["To"]),
            date=_decode_header(msg["Date"]),
            body_text=body_text,
            body_html=body_html,
            flags=flags,
        )


def _fetch_summary(conn: imaplib.IMAP4_SSL, uid: str) -> MessageSummary:
    typ, data = conn.uid(
        "fetch",
        uid,
        "(FLAGS BODY.PEEK[HEADER.FIELDS (SUBJECT FROM DATE)])",
    )
    if typ != "OK" or not data or data[0] is None:
        return MessageSummary(uid=uid, subject="(fetch failed)", sender="", date="")
    meta, raw = data[0]
    flags = _parse_flags(meta.decode() if isinstance(meta, bytes) else meta)
    headers = email.message_from_bytes(raw, policy=email.policy.default)
    return MessageSummary(
        uid=uid,
        subject=_decode_header(headers["Subject"]),
        sender=_decode_header(headers["From"]),
        date=_decode_header(headers["Date"]),
        flags=flags,
    )


def _parse_flags(meta: str) -> list[str]:
    # meta looks like: b'<uid> (FLAGS (\\Seen \\Answered) BODY[...] {1234}'
    start = meta.find("FLAGS (")
    if start < 0:
        return []
    end = meta.find(")", start)
    if end < 0:
        return []
    return meta[start + len("FLAGS (") : end].split()
