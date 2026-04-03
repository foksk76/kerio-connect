#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"

timestamp="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
repo_path="${repo_root}"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"

if git rev-parse --verify HEAD >/dev/null 2>&1; then
  head_short="$(git rev-parse --short HEAD)"
  head_subject="$(git log -1 --pretty=%s)"
else
  head_short="unborn"
  head_subject="No commits yet"
fi

remote_name="$(git remote | head -n 1 || true)"
if [ -n "${remote_name}" ]; then
  remote_url="$(git remote get-url "${remote_name}" 2>/dev/null || true)"
else
  remote_url=""
fi

mapfile -t staged_files < <(git diff --cached --name-only --diff-filter=ACMR || true)
if [ "${#staged_files[@]}" -eq 0 ]; then
  mapfile -t staged_files < <(git status --short | awk '{print $2}' || true)
fi

mapfile -t summary_files < <(
  printf '%s\n' "${staged_files[@]}" \
  | grep -vE '^(HANDOFF\.md|NEXT_STEPS\.md|CHANGELOG\.md)$' \
  || true
)
if [ "${#summary_files[@]}" -eq 0 ]; then
  summary_files=("${staged_files[@]}")
fi

compose_json="$(docker compose ps --format json 2>/dev/null || true)"
compose_lines="$(
  printf '%s\n' "${compose_json}" | while IFS= read -r line; do
    [ -n "${line}" ] || continue

    service="$(printf '%s\n' "${line}" | sed -n 's/.*"Service":"\([^"]*\)".*/\1/p')"
    status="$(printf '%s\n' "${line}" | sed -n 's/.*"Status":"\([^"]*\)".*/\1/p')"
    health="$(printf '%s\n' "${line}" | sed -n 's/.*"Health":"\([^"]*\)".*/\1/p')"

    [ -n "${service}" ] || continue
    [ -n "${status}" ] || continue

    if [ -n "${health}" ]; then
      printf -- '- `%s`: %s, health `%s`\n' "${service}" "${status}" "${health}"
    else
      printf -- '- `%s`: %s\n' "${service}" "${status}"
    fi
  done
)"
if [ -z "${compose_lines}" ]; then
  compose_lines='- `docker compose ps` unavailable'
fi

image_line="$(docker images --format '{{.Repository}}:{{.Tag}} {{.Size}}' 2>/dev/null | grep '^kerio-connect-kerio-connect:' | head -n 1 || true)"
if [ -z "${image_line}" ]; then
  image_line="kerio-connect image not built"
fi

postfix_state="$(systemctl is-active postfix 2>/dev/null || true)"
if [ -z "${postfix_state}" ]; then
  postfix_state="unknown"
fi
port25_line="$(ss -ltnp '( sport = :25 )' 2>/dev/null | tail -n +2 | head -n 1 | sed 's/^[[:space:]]*//' || true)"
if [ -n "${port25_line}" ]; then
  port25_status="busy: ${port25_line}"
else
  port25_status="free"
fi

diffstat="$(git diff --cached --stat -- "${summary_files[@]}" 2>/dev/null || true)"
if [ -z "${diffstat}" ]; then
  diffstat="$(git diff --stat -- "${summary_files[@]}" 2>/dev/null || true)"
fi

shortstat="$(git diff --cached --shortstat -- "${summary_files[@]}" 2>/dev/null || true)"
if [ -z "${shortstat}" ]; then
  shortstat="$(git diff --shortstat -- "${summary_files[@]}" 2>/dev/null || true)"
fi

contains_path() {
  local pattern="$1"
  printf '%s\n' "${summary_files[@]}" | grep -Eq "${pattern}"
}

declare -a change_areas=()
if contains_path '(^|/)(\.githooks/|scripts/update-commit-docs\.sh|scripts/enable-git-hooks\.sh)$'; then
  change_areas+=("Commit-time doc automation updated.")
fi
if contains_path '(^|/)(Dockerfile|docker-compose\.yml|\.env\.example|scripts/)'; then
  change_areas+=("Build and runtime configuration changed.")
fi
if contains_path '(^|/)(README\.md|HANDOFF\.md|NEXT_STEPS\.md|CHANGELOG\.md)$'; then
  change_areas+=("Project documentation refreshed.")
fi
if contains_path '(^|/)artifacts/'; then
  change_areas+=("Artifact handling changed.")
fi
if [ "${#change_areas[@]}" -eq 0 ]; then
  change_areas+=("Repository files updated.")
fi

render_array_or_none() {
  local prefix="$1"
  shift || true

  if [ "$#" -eq 0 ] || [ -z "${1:-}" ]; then
    printf -- "%snone\n" "${prefix}"
    return
  fi

  local item
  for item in "$@"; do
    [ -n "${item}" ] || continue
    printf -- "%s%s\n" "${prefix}" "${item}"
  done
}

render_file_list() {
  if [ "${#summary_files[@]}" -eq 0 ] || [ -z "${summary_files[0]:-}" ]; then
    printf -- "- none\n"
    return
  fi

  local file
  for file in "${summary_files[@]}"; do
    [ -n "${file}" ] || continue
    printf -- '- `%s`\n' "${file}"
  done
}

render_change_areas() {
  local item
  for item in "${change_areas[@]}"; do
    printf -- "- %s\n" "${item}"
  done
}

if printf '%s\n' "${compose_json}" | grep -q '"Health":"healthy"'; then
  first_step="Open \`https://localhost:4040/admin\` and finish the first-run wizard."
elif printf '%s\n' "${compose_json}" | grep -q '"State":"running"'; then
  first_step="Wait for the container to become healthy, then open \`https://localhost:4040/admin\`."
else
  first_step="Run \`docker compose up -d\` and confirm the service starts."
fi

if [ "${postfix_state}" = "active" ] || [ "${port25_status}" != "free" ]; then
  second_step="Keep host port \`25\` free for Kerio by stopping or disabling the local MTA, or remap \`KERIO_SMTP_PORT\` in \`.env\`."
else
  second_step="Decide whether to disable \`postfix\` permanently if this host should keep port \`25\` free after reboot."
fi

cat > "${repo_root}/HANDOFF.md" <<EOF
# Handoff

## Purpose

This file captures the current working state of the Kerio Connect lab repository so work can resume quickly in another chat, shell, or host session.

## Current Snapshot

- Updated: ${timestamp}
- Repository: \`${repo_path}\`
- Branch: \`${branch}\`
- Base HEAD: \`${head_short}\` - ${head_subject}
- Remote: \`${remote_name:-none}\`${remote_url:+ - \`${remote_url}\`}
- Kerio image: \`${image_line}\`
- Postfix service: \`${postfix_state}\`
- Host port 25: \`${port25_status}\`

## Compose Status

$(printf '%s\n' "${compose_lines}")

## Pending Change Areas

$(render_change_areas)

## Pending Source Files

$(render_file_list)

## Pending Diffstat

${shortstat:-No staged diffstat available.}

\`\`\`
${diffstat:-No staged diffstat available.}
\`\`\`

## Resume Notes

1. The build now auto-resolves the official Kerio Linux DEB from the public Kerio archive, with local \`artifacts/\` and explicit \`KERIO_DOWNLOAD_URL\` overrides still supported.
2. The current container was able to reach \`cdn.kerio.com\` and \`appmanager.gfi.com\`, and the image build completed successfully on this host.
3. The current runtime path still needs normal first-run verification inside Kerio Connect Administration after the initial wizard is completed.
4. Commit-time automation for \`HANDOFF.md\`, \`NEXT_STEPS.md\`, and \`CHANGELOG.md\` lives in \`scripts/update-commit-docs.sh\` and is triggered by \`.githooks/pre-commit\`.

## Suggested Resume Commands

\`\`\`bash
cd /root/kerio-connect
git status
docker compose ps
docker compose logs --tail=200 kerio-connect
\`\`\`

## Official Hosts

- https://cdn.kerio.com/
- https://appmanager.gfi.com/
- https://support.kerioconnect.gfi.com/
EOF

cat > "${repo_root}/NEXT_STEPS.md" <<EOF
# Next Steps

Generated automatically on ${timestamp}.

## Current Observed State

- Repository path: \`${repo_path}\`
- Branch: \`${branch}\`
- Kerio image: \`${image_line}\`
- Postfix service: \`${postfix_state}\`
- Host port 25: \`${port25_status}\`

## Compose Status

$(printf '%s\n' "${compose_lines}")

## Immediate Steps

1. ${first_step}
2. ${second_step}
3. Verify the package layout inside the container or image:
   - \`/etc/init.d/kerio-connect\`
   - \`/opt/kerio/mailserver/mailserver.cfg\`
   - \`/opt/kerio/mailserver/users.cfg\`
   - \`/opt/kerio/mailserver/license\`
   - \`/opt/kerio/mailserver/store\`
4. Confirm that \`scripts/configure-log-root.sh\` still matches the real \`mailserver.cfg\` shape and that logs can be redirected to \`/opt/kerio/logs\`.
5. Enable external Syslog logging in Kerio Connect Administration and point it at the Logstash receiver once the wizard is complete.

## Commit Automation

Run this once per clone or host to enable repository hooks:

\`\`\`bash
scripts/enable-git-hooks.sh
\`\`\`
EOF

cat > "${repo_root}/CHANGELOG.md" <<EOF
# Changelog

All notable changes to this lab repository are tracked here.

## Unreleased

### Current Commit Snapshot

- Updated: ${timestamp}
- Branch: \`${branch}\`
- Base HEAD: \`${head_short}\`
- Remote: \`${remote_name:-none}\`

### Change Areas

$(render_change_areas)

### Source Files In This Commit

$(render_file_list)

### Diffstat

- ${shortstat:-No staged diffstat available.}

\`\`\`
${diffstat:-No staged diffstat available.}
\`\`\`

### Baseline

- Debian 13 Kerio Connect lab scaffold.
- Docker Compose wrapper, runtime scripts, and healthcheck.
- README with VM requirements, first-run flow, Syslog notes, and commit-time doc automation.
EOF
