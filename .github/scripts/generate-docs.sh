#!/usr/bin/env bash
set -euo pipefail

# Determine repo root path relative to this script
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Path to terraform-docs config
TFDOCS_CONFIG="${REPO_ROOT}/.terraform-docs.yml"

# Check terraform-docs is installed
if ! command -v terraform-docs &> /dev/null; then
  echo "❌ terraform-docs is not installed. Install it from https://terraform-docs.io/"
  exit 1
fi

echo "📘 Generating module documentation using config at: $TFDOCS_CONFIG"
echo

# Loop through all submodules with a variables.tf file
find "${REPO_ROOT}/modules" -type f -name "variables.tf" | while read -r tf_file; do
  MODULE_DIR="$(dirname "$tf_file")"
  echo "📄 Updating docs for module: ${MODULE_DIR#$REPO_ROOT/}"

  terraform-docs --config "$TFDOCS_CONFIG" "$MODULE_DIR" > "$MODULE_DIR/README.md"
done

echo
echo "✅ Documentation generated for all modules."
