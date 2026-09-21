#!/usr/bin/env bash
# export-workflows.sh
# Pulls the running n8n instance's workflows into n8n/workflows/ as JSON.
#
# IMPORTANT: n8n binds exported workflow JSON to credential IDs that do not
# survive a clone. Importing a committed workflow into a new instance requires
# re-selecting credentials by hand on each imported workflow. This is accepted
# V1 friction (see design.md §5) and is not worked around with embedded keys.
#
# Usage:
#   N8N_BASE_URL=https://n8n.example.com N8N_API_KEY=... ./scripts/export-workflows.sh
#
# Requires: curl, jq

set -euo pipefail

# Configuration from environment
N8N_BASE_URL="${N8N_BASE_URL:-}"
N8N_API_KEY="${N8N_API_KEY:-}"
OUTPUT_DIR="${OUTPUT_DIR:-n8n/workflows}"

if [[ -z "$N8N_BASE_URL" ]]; then
  echo "ERROR: N8N_BASE_URL not set (e.g., https://n8n.example.com)" >&2
  exit 1
fi

if [[ -z "$N8N_API_KEY" ]]; then
  echo "ERROR: N8N_API_KEY not set (create in n8n > Settings > API)" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Fetching workflow list from $N8N_BASE_URL..."

# Fetch all workflows (paginated)
cursor=""
page=1
all_workflows=()

while true; do
  url="${N8N_BASE_URL}/api/v1/workflows?limit=50"
  [[ -n "$cursor" ]] && url="${url}&cursor=${cursor}"

  response=$(curl -sSf -H "X-N8N-API-KEY: ${N8N_API_KEY}" "$url")

  workflows=$(echo "$response" | jq -c '.data[]')
  if [[ -z "$workflows" ]]; then
    break
  fi

  while IFS= read -r wf; do
    all_workflows+=("$wf")
  done <<< "$workflows"

  cursor=$(echo "$response" | jq -r '.nextCursor // empty')
  [[ -z "$cursor" ]] && break

  ((page++))
done

if [[ ${#all_workflows[@]} -eq 0 ]]; then
  echo "No workflows found."
  exit 0
fi

echo "Exporting ${#all_workflows[@]} workflow(s) to $OUTPUT_DIR/..."

for wf in "${all_workflows[@]}"; do
  id=$(echo "$wf" | jq -r '.id')
  name=$(echo "$wf" | jq -r '.name')

  # Sanitize name for filename: lowercase, replace non-alnum with dash, trim dashes
  filename=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//; s/-$//')
  filepath="${OUTPUT_DIR}/${filename}.json"

  # Fetch full workflow details
  detail=$(curl -sSf -H "X-N8N-API-KEY: ${N8N_API_KEY}" "${N8N_BASE_URL}/api/v1/workflows/${id}")

  # Write with pretty JSON
  echo "$detail" | jq '.' > "$filepath"
  echo "  $filepath"
done

echo "Done."