#!/usr/bin/env bash
#
# run_hippunfold_example.sh
#
# Purpose:
#   Minimal example wrapper showing how you might call HippUnfold on
#   BIDS-structured data in ../data/bids and direct outputs to
#   ../data/hippunfold.
#
#   This script is intentionally simple and may need to be adjusted to match
#   your installed HippUnfold version and command-line API.
#
# Requirements:
#   - HippUnfold installed and available on PATH (e.g., as `hippunfold`).
#
# Usage (example):
#   bash run_hippunfold_example.sh \
#       --bids-dir ../data/bids \
#       --output-dir ../data/hippunfold \
#       --subject sub-001 \
#       --session ses-01
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BIDS_DIR="${ROOT_DIR}/data/bids"
OUT_DIR="${ROOT_DIR}/data/hippunfold"
SUBJECT=""
SESSION=""

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [options]

Options:
  --bids-dir DIR      BIDS root directory (default: ${BIDS_DIR})
  --output-dir DIR    HippUnfold output directory (default: ${OUT_DIR})
  --subject ID        Subject ID (e.g., sub-001)
  --session ID        Session ID (e.g., ses-01) [optional]
  -h, --help          Show this help message and exit

Notes:
  - This is a template. Consult HippUnfold's documentation for the
    exact CLI syntax and supported options:
      https://github.com/khanlab/hippunfold
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bids-dir)   BIDS_DIR="$2"; shift 2 ;;
    --output-dir) OUT_DIR="$2";  shift 2 ;;
    --subject)    SUBJECT="$2";  shift 2 ;;
    --session)    SESSION="$2";  shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "${SUBJECT}" ]]; then
  echo "[ERROR] --subject is required." >&2
  usage
  exit 1
fi

if ! command -v hippunfold >/dev/null 2>&1; then
  echo "[ERROR] hippunfold not found on PATH. Install HippUnfold or update PATH." >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

echo "[INFO] Running HippUnfold..."
echo "[INFO] BIDS dir:   ${BIDS_DIR}"
echo "[INFO] Output dir: ${OUT_DIR}"
echo "[INFO] Subject:    ${SUBJECT}"
if [[ -n "${SESSION}" ]]; then
  echo "[INFO] Session:    ${SESSION}"
fi

# NOTE:
#   Replace the placeholder CLI below with the actual HippUnfold command
#   for your version. Example (subject-level):
#
#   hippunfold \
#     --bids-dir "${BIDS_DIR}" \
#     --output-dir "${OUT_DIR}" \
#     --participant-label "${SUBJECT}" \
#     --session-label "${SESSION}" \
#     --nthreads 4
#

CMD=(hippunfold
  "--bids-dir" "${BIDS_DIR}"
  "--output-dir" "${OUT_DIR}"
  "--participant-label" "${SUBJECT}"
)

if [[ -n "${SESSION}" ]]; then
  CMD+=("--session-label" "${SESSION}")
fi

echo "[INFO] Command:"
printf ' %q' "${CMD[@]}"
echo

# Uncomment the next line once you've verified the CLI matches your HippUnfold version.
# "${CMD[@]}"

echo "[INFO] This is a template command. Edit run_hippunfold_example.sh to enable actual execution."

exit 0

