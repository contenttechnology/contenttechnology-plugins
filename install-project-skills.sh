#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Copy local project skills into the global Codex skills directory.

Usage:
  install-project-skills.sh [--source DIR] [--dest DIR] [--overwrite] [--dry-run]

Options:
  --source DIR   Root directory to scan for skill folders (default: <repo>/plugins)
  --dest DIR     Destination skills directory (default: $CODEX_HOME/skills or ~/.codex/skills)
  --overwrite    Replace destination skill if it already exists
  --dry-run      Print actions without copying files
  -h, --help     Show this help text
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SOURCE="${SCRIPT_DIR}/plugins"
DEFAULT_DEST="${CODEX_HOME:-$HOME/.codex}/skills"

SOURCE_DIR="$DEFAULT_SOURCE"
DEST_DIR="$DEFAULT_DEST"
OVERWRITE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE_DIR="${2:-}"
      shift 2
      ;;
    --dest)
      DEST_DIR="${2:-}"
      shift 2
      ;;
    --overwrite)
      OVERWRITE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$SOURCE_DIR" || -z "$DEST_DIR" ]]; then
  echo "Source and destination must not be empty." >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

SKILL_FILES=()
while IFS= read -r skill_file; do
  SKILL_FILES+=("$skill_file")
done < <(find "$SOURCE_DIR" -type f -name SKILL.md | LC_ALL=C sort)

if [[ ${#SKILL_FILES[@]} -eq 0 ]]; then
  echo "No skills found under: $SOURCE_DIR"
  exit 0
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "$DEST_DIR"
fi

copied=0
skipped=0

for skill_file in "${SKILL_FILES[@]}"; do
  skill_dir="$(dirname "$skill_file")"
  skill_name="$(basename "$skill_dir")"
  target_dir="${DEST_DIR}/${skill_name}"

  if [[ -d "$target_dir" && "$OVERWRITE" -ne 1 ]]; then
    echo "Skipping ${skill_name}: destination exists (${target_dir})"
    skipped=$((skipped + 1))
    continue
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ -d "$target_dir" && "$OVERWRITE" -eq 1 ]]; then
      echo "[dry-run] Would replace ${target_dir} from ${skill_dir}"
    else
      echo "[dry-run] Would copy ${skill_dir} -> ${target_dir}"
    fi
    copied=$((copied + 1))
    continue
  fi

  if [[ -d "$target_dir" && "$OVERWRITE" -eq 1 ]]; then
    rm -rf "$target_dir"
  fi

  cp -R "$skill_dir" "$target_dir"
  echo "Installed ${skill_name} -> ${target_dir}"
  copied=$((copied + 1))
done

echo "Done. Copied: ${copied}, skipped: ${skipped}, destination: ${DEST_DIR}"
