# Changelog

This file is maintained as a project journal rather than an auto-generated diff snapshot.
It records releases, major repository changes, fixed bugs, operational milestones, and the commits that marked those milestones.

## Unreleased

No unreleased changes are recorded yet.

## v0.2.1 - 2026-04-07

Patch release focused on project-family README alignment and bilingual onboarding for lab engineers. No runtime behavior changed.

### Added

- Russian onboarding README for quick lab orientation and translation parity with the English README.

### Changed

- The main README now follows the shared Kerio Connect Monitoring & Logging project-family structure, including the required language switcher, quick-start flow, verification checklist, troubleshooting sections, governance links, and GitHub Release Notes guidance.
- Documentation language guidance now clarifies that English remains canonical for project documentation, reviews, issues, and release notes, while Russian README updates are welcome for lab onboarding.
- README terminology now uses engineer-focused wording for the target audience and release-note guidance.

### Validation

- README structure was verified against the shared English and Russian templates.
- Markdown whitespace validation passed for the updated README files.
- No Docker, Compose, Kerio runtime, port mapping, or CI workflow behavior changed in this patch.

### Related Commits

- `7ed8233` Standardize bilingual README onboarding

## v0.2.0 - 2026-04-05

Stable release focused on repository maturity, reproducible onboarding, and explicit governance around the Kerio Connect lab wrapper.

### Added

- Apache 2.0 `LICENSE` for the repository wrapper code, scripts, and documentation.
- `THIRD_PARTY_NOTICE.md` clarifying that Kerio Connect itself remains proprietary vendor software and is not distributed under the repository license.
- Repository governance and contribution entry points through `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`, `CODE_OF_CONDUCT.md`, issue templates, a pull request template, and release categories.

### Changed

- `README.md` was refactored to the shared project-family documentation standard with a structured quick start, example input/output, verification checklist, and troubleshooting flow.
- Admin access guidance now explicitly documents the first-run `http://localhost:4040/admin/` path and the post-setup redirect to `https://localhost:4040/admin/`.
- Support and security guidance were tightened to better separate public troubleshooting from sensitive reporting.

### Fixed

- GitHub-hosted CI now performs a stable smoke check that validates Kerio availability from inside the container and confirms published admin-port mapping.
- Repository onboarding is clearer for new users because the main README and governance files now expose exact entry points for setup, contribution, support, and legal scope.

### Operational Milestones

- The repository now has a stable open-source license for the wrapper layer while preserving an explicit proprietary-software boundary for Kerio Connect itself.
- The `0.2.x` release line now moves from alpha into a stable product release.

### Related Commits

- `c92b9a3` Fix GitHub Actions admin smoke check
- `1b568e3` Fix CI smoke check on GitHub runners
- `30cc22d` Release v0.2.0-alpha.2

## v0.2.0-alpha.2 - 2026-04-05

Follow-up alpha focused on making the GitHub repository clearer for contributors and more reliable for GitHub-hosted CI.

### Added

- Community health files for support, security reporting, contribution guidance, code of conduct, and issue / PR templates.
- `.github/release.yml` to organize future GitHub release notes into clearer categories.

### Changed

- `README.md` now has a clearer top-level status, target audience, maintainer entry point, and support links for repository visitors.
- The GitHub Actions smoke check was adjusted to validate the admin endpoint from inside the container and confirm port publishing, avoiding flaky runner-host HTTPS probing.

### Fixed

- `Docker Lab CI` now completes successfully on GitHub-hosted runners instead of failing in the final smoke-check step.
- Repository onboarding is clearer for new users because support, contribution, and security paths are now explicit instead of implicit.

### Operational Milestones

- Community health scaffolding is now present in-repo instead of being tracked only as a backlog item.
- GitHub Actions `Docker Lab CI` was verified green after the runner-specific smoke-check fix.

### Related Commits

- `c92b9a3` Fix GitHub Actions admin smoke check
- `1b568e3` Fix CI smoke check on GitHub runners

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
