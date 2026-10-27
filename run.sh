#!/usr/bin/env bash
# Runs self-hosted Renovate in --dry-run=full against this repo on GitHub and
# summarizes what it would commit to each branch.
#
# Needs GITHUB_TOKEN (any token that can read public repos).
set -euo pipefail

repo="${REPO:-teekennedy/renovate-terraform-duplicate-lock}"
cd "$(dirname "$0")"

docker build -q -t renovate-tf-repro . >/dev/null

docker run --rm \
  -e RENOVATE_PLATFORM=github \
  -e RENOVATE_TOKEN="${GITHUB_TOKEN:?set GITHUB_TOKEN}" \
  -e RENOVATE_REPOSITORIES="$repo" \
  -e RENOVATE_DRY_RUN=full \
  -e RENOVATE_ALLOWED_COMMANDS='["^terraform "]' \
  -e LOG_LEVEL=debug \
  -e LOG_FORMAT=json \
  renovate-tf-repro >renovate.log 2>&1 || true

# Lock files Renovate's terraform manager produced, per branch.
jq -r 'select(.updatedArtifacts) |
  "\(.branch): \(.msg)\n" + (.updatedArtifacts | map("  - \(.)") | join("\n"))' renovate.log

# Files the post-upgrade task changed, per branch.
jq -r 'select(.msg == "Post-upgrade file saved") | "\(.branch): post-upgrade saved \(.file)"' renovate.log

# What would be committed: each file entry, in commit order, with its hash count.
jq -r 'select(.msg | startswith("DRY-RUN: Would commit files to branch")) | select(.files) |
  "\(.branchName): would commit " +
  (.files | to_entries | map("\n  [\(.key)] \(.value.path) (\(.value.rawContents | [scan("\"(h1|zh):")] | length) hashes)") | join(""))' renovate.log
