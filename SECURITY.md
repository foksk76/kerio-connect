# Security Policy

## Supported Versions

Security fixes and review effort are most realistic for:

- the current `main` branch
- the latest stable release tag
- the latest alpha tag

Older snapshots may still work, but they should not be assumed to receive follow-up fixes.

## What Counts As A Security Issue Here

Examples:

- leaked credentials, license keys, or secrets in repository content or logs
- unsafe defaults in the Docker wrapper
- unintended exposure of administrative or mail interfaces
- persistence or CI behavior that can leak sensitive data

## How To Report

- Do not publish secrets, mailbox contents, exploit details, or private infrastructure information in a normal public issue.
- If GitHub private vulnerability reporting is enabled for this repository, use that path first.
- If it is not enabled, open a minimal public issue asking for a private contact path without including the sensitive details, or contact the maintainer through the repository owner account on GitHub.

## What To Include

- affected tag or commit
- a short description of the impact
- reproduction conditions
- whether the issue affects only the lab wrapper or also the underlying vendor product

## Response Expectations

This is a public lab repository, not a staffed security program. Reports will be handled in good faith, but no SLA is implied.
