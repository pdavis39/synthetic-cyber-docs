#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ─── 1) Sanity checks ────────────────────────────────────────────────────

# Check for setfattr & uuidgen
for cmd in setfattr uuidgen; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ Required command '$cmd' not found."
    echo "   On Ubuntu/Debian try: sudo apt update && sudo apt install attr uuid-runtime"
    exit 1
  fi
done

# Check that synthetic_data directory exists
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ -d "${SCRIPT_DIR}/synthetic_data" ]]; then
  DIR="${SCRIPT_DIR}/synthetic_data"
elif [[ -d "$SCRIPT_DIR" && "$(basename "$SCRIPT_DIR")" == "synthetic_data" ]]; then
  DIR="$SCRIPT_DIR"
else
  echo "❌ Could not locate 'synthetic_data' directory next to this script."
  exit 1
fi

# Check that user_xattr is enabled on the filesystem
FS_DEV=$(df "$DIR" | tail -1 | awk '{print $1}')
if ! mount | grep -oE "${FS_DEV}.*user_xattr" >/dev/null; then
  echo "❌ 'user_xattr' is not enabled on $FS_DEV."
  echo "   You may need to remount with: sudo mount -o remount,user_xattr <mountpoint>"
  exit 1
fi

echo "✅ All prereqs satisfied. Populating xattrs on files in '$DIR' …"

# ─── 2) Define your 30 tags ─────────────────────────────────────────────
TAGS=(
  classification classification_level originator_id data_type sensitivity
  transfer_control data_owner data_steward dissemination_control
  release_authority document_type teaming_partner handling_descriptor
  distribution_statement sci_control caveats ps_percent_complete
  point_of_contact report_version system_of_record citation
  related_doc platform environment operation_name mission_area
  geo_scope cyber_domain policy_impact audit_trail
)

# ─── 3) Loop & set xattrs ────────────────────────────────────────────────
for file in "$DIR"/*.txt; do
  [[ -f "$file" ]] || continue
  echo "→ $file"
  for tag in "${TAGS[@]}"; do
    UUID=$(uuidgen)
    echo "   setting user.$tag = $UUID"
    setfattr -n "user.$tag" -v "$UUID" "$file"
  done
done

echo "✅ Done! You can spot-check with:"
echo "    getfattr -d '$DIR'/$(basename "$(ls "$DIR"/*.txt | head -1)")"
