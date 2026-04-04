#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"

timestamp="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
repo_path="${repo_root}"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
state_file="${repo_root}/.lab-state.env"

if [ -f "${state_file}" ]; then
  # shellcheck disable=SC1090
  . "${state_file}"
fi

kerio_first_run_status="${KERIO_FIRST_RUN_STATUS:-}"
kerio_primary_domain="${KERIO_PRIMARY_DOMAIN:-}"
kerio_hostname="${KERIO_HOSTNAME:-}"
kerio_message_store="${KERIO_MESSAGE_STORE:-}"
kerio_admin_account="${KERIO_ADMIN_ACCOUNT:-}"
kerio_license_note="${KERIO_LICENSE_NOTE:-}"
kerio_dns_note="${KERIO_DNS_NOTE:-}"

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
  | grep -vE '^(HANDOFF\.md|NEXT_STEPS\.md)$' \
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

render_runtime_lines() {
  if [ -n "${kerio_first_run_status}" ]; then
    printf -- '- First run: `%s`\n' "${kerio_first_run_status}"
  fi
  if [ -n "${kerio_admin_account}" ]; then
    printf -- '- Admin account: `%s`\n' "${kerio_admin_account}"
  fi
  if [ -n "${kerio_primary_domain}" ]; then
    printf -- '- Primary domain: `%s`\n' "${kerio_primary_domain}"
  fi
  if [ -n "${kerio_hostname}" ]; then
    printf -- '- Hostname: `%s`\n' "${kerio_hostname}"
  fi
  if [ -n "${kerio_message_store}" ]; then
    printf -- '- Message store: `%s`\n' "${kerio_message_store}"
  fi
  if [ -n "${kerio_license_note}" ]; then
    printf -- '- License note: `%s`\n' "${kerio_license_note}"
  fi
  if [ -n "${kerio_dns_note}" ]; then
    printf -- '- DNS note: `%s`\n' "${kerio_dns_note}"
  fi
}

if [ "${kerio_first_run_status}" = "completed" ] && [ -n "${kerio_admin_account}" ]; then
  first_step="Sign in to \`https://localhost:4040/admin\` as \`${kerio_admin_account}\` and continue post-setup tasks."
elif [ "${kerio_first_run_status}" = "completed" ]; then
  first_step="Sign in to \`https://localhost:4040/admin\` and continue post-setup tasks."
elif printf '%s\n' "${compose_json}" | grep -q '"Health":"healthy"'; then
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

if [ -n "${kerio_license_note}" ]; then
  third_step="${kerio_license_note}"
else
  third_step="If you need a trial or temporary license, use the manual GFI Free Trial flow documented in \`README.md\`."
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

## Recorded Lab State

$(render_runtime_lines)

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
3. Runtime milestones recorded in \`.lab-state.env\` are folded into this handoff so first-run progress is not lost between chats or commits.
4. Commit-time automation for \`HANDOFF.md\` and \`NEXT_STEPS.md\` lives in \`scripts/update-commit-docs.sh\` and is triggered by \`.githooks/pre-commit\`.

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
$(render_runtime_lines)

## Compose Status

$(printf '%s\n' "${compose_lines}")

## Immediate Steps

1. ${first_step}
2. ${second_step}
3. ${third_step}
4. Verify the package layout inside the container or image:
   - \`/etc/init.d/kerio-connect\`
   - \`/opt/kerio/mailserver/mailserver.cfg\`
   - \`/opt/kerio/mailserver/users.cfg\`
   - \`/opt/kerio/mailserver/license\`
   - \`/opt/kerio/mailserver/store\`
5. Confirm that \`scripts/configure-log-root.sh\` still matches the real \`mailserver.cfg\` shape and that logs can be redirected to \`/opt/kerio/logs\`.
6. Enable external Syslog logging in Kerio Connect Administration and point it at the Logstash receiver once the wizard is complete.

## Commit Automation

Run this once per clone or host to enable repository hooks:

\`\`\`bash
scripts/enable-git-hooks.sh
\`\`\`
EOF
