# Changelog

This file is maintained as a project journal rather than an auto-generated diff snapshot.
It records releases, major repository changes, fixed bugs, operational milestones, and the commits that marked those milestones.

## Unreleased

No unreleased changes are recorded yet.

## v0.2.0-alpha.1 - 2026-04-05

Minor alpha focused on bringing GitHub Actions CI in line with the real Docker lab workflow.

### Changed

- `.github/workflows/docker-image.yml` now validates the actual Compose configuration instead of running an isolated `docker build`.
- The CI job now uses the same build inputs as the lab, including optional Kerio download overrides through repository variables.
- The workflow now boots the Kerio lab on isolated CI-only ports, waits for the container healthcheck, smoke-tests the admin endpoint, and tears the stack down cleanly.

### Fixed

- The GitHub Actions workflow no longer drifts from the documented local workflow in `README.md`.
- CI validation now exercises the same `docker compose build` and `docker compose up` path used by operators in the lab.

### Operational Milestones

- First GitHub Actions workflow for the lab was added and then corrected to match the real runtime model.
- Local verification confirmed the CI-style flow succeeds end to end: `compose config`, image build, container startup, healthcheck, admin endpoint probe, and teardown.

### Related Commits

- `00bdacf` Create docker-image.yml

## v0.1.0 - 2026-04-04

First stable release of the Debian 13 / Docker-based Kerio Connect lab.

### Changed

- `CHANGELOG.md` is now curated manually as a running journal of releases, fixed bugs, new features, and operational milestones.
- Commit-time automation now refreshes only `HANDOFF.md` and `NEXT_STEPS.md`, leaving the changelog under manual release control.
- Runtime state tracking now records the active external Syslog setup so generated handoff and next-step docs reflect the actual lab status.

### Fixed

- `NEXT_STEPS.md` now stops asking operators to enable Syslog after it is already configured and instead prompts them to verify remote delivery.

### Operational Milestones

- First-run setup completed successfully for `kerio.lo`.
- Administrative mailbox `doge@kerio.lo` was created and retained across restarts.
- Trial licensing survived restart and the lab now starts in a registered state.
- External Syslog was enabled for `mail`, `operations`, `security`, `spam`, and `audit` to `elastic.lo:5514` with application name `kerio`.
- End-to-end local mail delivery was validated with a test message delivered to `doge@kerio.lo`.

### Related Commits

- `cfc2abd` Curate changelog history and stop auto-overwriting it

## v0.1.0-alpha.1 - 2026-04-04

First usable alpha of the Debian 13 / Docker-based Kerio Connect lab.

### Added

- Official Kerio archive auto-download during `docker compose build`, with support for local `artifacts/` and explicit `KERIO_DOWNLOAD_URL` overrides.
- Runtime lab-state tracking in `.lab-state.env` for first-run progress and operator notes.
- Dedicated `kerio_license` Docker volume mapped directly to `/opt/kerio/mailserver/license`.
- First-run documentation covering the current GFI Free Trial flow, Debian host preparation, Syslog guidance, and the recommendation to take a Proxmox backup after initial setup.

### Changed

- Repository documentation was aligned with the renamed repository path `/root/kerio-connect`.
- `README.md`, `HANDOFF.md`, and `NEXT_STEPS.md` were expanded to reflect the new VM, first-run workflow, and current HomeLab DNS assumptions.

### Fixed

- `scripts/configure-log-root.sh` now edits the real persistent `mailserver.cfg` target instead of breaking the symlink and losing runtime changes.
- Repeated first-run wizard prompts after container restarts were stabilized by persisting the effective config state.
- License activation stopped failing on `License directory /opt/kerio/mailserver/license does not exist` by replacing the old symlinked license layout with a real runtime directory backed by a dedicated Docker volume.
- Debian locale warnings for English and Russian were fixed by generating `en_US.UTF-8` and `ru_RU.UTF-8` in the image.
- Initial startup on the new VM no longer conflicts with the local host MTA because the host-side `postfix` conflict was identified and documented.

### Operational Milestones

- Initial configuration completed for the lab domain `kerio.lo`.
- Administrative account created: `doge@kerio.lo`.
- Trial registration fallback was moved from the broken legacy `kerio.com` flow to the current GFI trial entry point.
- Trial license activation was validated successfully and confirmed to survive a restart.
- Alpha tag `v0.1.0-alpha.1` was published.

### Related Commits

- `574e8ab` Alpha release: stabilize first run, licensing, and persistence

## Bootstrap - 2026-04-03

Initial repository bootstrap and commit-time handoff automation.

### Added

- Base Debian 13 Kerio Connect lab scaffold with `Dockerfile`, `docker-compose.yml`, runtime scripts, and healthcheck.
- `HANDOFF.md` and `NEXT_STEPS.md` to carry forward context between chats and hosts.
- Git-hook driven status-doc automation through `.githooks/pre-commit`, `scripts/update-commit-docs.sh`, and `scripts/enable-git-hooks.sh`.

### Related Commits

- `38f3092` Initial commit
- `acc373c` Add handoff and next steps docs
- `8f3a95b` Automate commit-time project status docs
