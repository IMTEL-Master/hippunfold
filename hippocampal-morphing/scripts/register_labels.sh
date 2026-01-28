#!/usr/bin/env bash
#
# register_labels.sh
#
# Purpose:
#   Use ANTs to register atlas labelmaps (e.g., hippocampal labels) into
#   template or subject spaces for downstream HippUnfold processing.
#
#   This script is intentionally generic and heavily commented. You will
#   likely want to clone and customize it per-species (mouse, rat, human,
#   macaque, marmoset).
#
# Requirements:
#   - ANTs binaries on PATH:
#       antsRegistration
#       antsApplyTransforms
#
# Usage (generic):
#   bash register_labels.sh \
#       --template /path/to/template_T1.nii.gz \
#       --labels   /path/to/atlas_labels.nii.gz \
#       --output   /path/to/output_dir \
#       [--moving  /path/to/moving_image.nii.gz] \
#       [--dim 3] [--rigid-affine] [--nonlinear]
#
# Example (mouse, Allen → custom template):
#   bash register_labels.sh \
#       --template ../data/raw/allen_ccf_mouse_T2.nii.gz \
#       --labels   ../data/raw/allen_ccf_mouse_labels.nii.gz \
#       --output   ../data/labels/mouse/
#

set -euo pipefail

###############################################################################
# Argument parsing
###############################################################################

TEMPLATE_IMAGE=""
LABEL_IMAGE=""
MOVING_IMAGE=""
OUTPUT_DIR=""
DIM=3
DO_RIGID_AFFINE=1
DO_NONLINEAR=1

usage() {
  cat <<EOF
Usage:
  $(basename "$0") --template TEMPLATE.nii.gz --labels LABELS.nii.gz --output OUTPUT_DIR [options]

Required:
  --template PATH   Target space image (e.g., species template T1/T2)
  --labels PATH     Atlas label image to be mapped into template space
  --output DIR      Output directory (will be created if needed)

Optional:
  --moving PATH     Moving image (if different from labels space). If not set,
                    the labels image is assumed to be in the same space as the
                    moving anatomical image.
  --dim N          Image dimensionality (default: 3)
  --rigid-affine  Enable rigid+affine stages (default)
  --no-rigid-affine  Disable rigid+affine stages
  --nonlinear     Enable nonlinear registration (SyN) (default)
  --no-nonlinear  Disable nonlinear registration

Notes:
  - This script computes transforms from moving → template space and then
    applies them to the label image with nearest-neighbor interpolation.
  - Customize antsRegistration parameters for each species as needed.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template) TEMPLATE_IMAGE="$2"; shift 2 ;;
    --labels)   LABEL_IMAGE="$2";   shift 2 ;;
    --moving)   MOVING_IMAGE="$2";  shift 2 ;;
    --output)   OUTPUT_DIR="$2";    shift 2 ;;
    --dim)      DIM="$2";           shift 2 ;;
    --rigid-affine)     DO_RIGID_AFFINE=1; shift ;;
    --no-rigid-affine)  DO_RIGID_AFFINE=0; shift ;;
    --nonlinear)        DO_NONLINEAR=1; shift ;;
    --no-nonlinear)     DO_NONLINEAR=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "${TEMPLATE_IMAGE}" || -z "${LABEL_IMAGE}" || -z "${OUTPUT_DIR}" ]]; then
  echo "[ERROR] --template, --labels, and --output are required." >&2
  usage
  exit 1
fi

if [[ -z "${MOVING_IMAGE}" ]]; then
  MOVING_IMAGE="${LABEL_IMAGE}"
fi

mkdir -p "${OUTPUT_DIR}"

###############################################################################
# Paths and sanity checks
###############################################################################

for f in "${TEMPLATE_IMAGE}" "${LABEL_IMAGE}" "${MOVING_IMAGE}"; do
  if [[ ! -f "${f}" ]]; then
    echo "[ERROR] File not found: ${f}" >&2
    exit 1
  fi
done

if ! command -v antsRegistration >/dev/null 2>&1; then
  echo "[ERROR] antsRegistration not found on PATH. Install ANTs or update PATH." >&2
  exit 1
fi

if ! command -v antsApplyTransforms >/dev/null 2>&1; then
  echo "[ERROR] antsApplyTransforms not found on PATH. Install ANTs or update PATH." >&2
  exit 1
fi

###############################################################################
# Registration configuration
###############################################################################

OUT_PREFIX="${OUTPUT_DIR}/reg_"
WARPED_IMAGE="${OUT_PREFIX}warped.nii.gz"

TRANSFORMS=()

REG_CMD=(antsRegistration
  --dimensionality "${DIM}"
  --float 0
  --output "${OUT_PREFIX}"
  --use-histogram-matching 1
  --winsorize-image-intensities "[0.005,0.995]"
  --initial-moving-transform "[${TEMPLATE_IMAGE},${MOVING_IMAGE},1]"
)

if [[ "${DO_RIGID_AFFINE}" -eq 1 ]]; then
  REG_CMD+=(
    # Rigid
    --transform "Rigid[0.1]"
    --metric "MI[${TEMPLATE_IMAGE},${MOVING_IMAGE},1,32,Regular,0.25]"
    --convergence "[1000x500x250x100,1e-6,10]"
    --shrink-factors "8x4x2x1"
    --smoothing-sigmas "3x2x1x0vox"

    # Affine
    --transform "Affine[0.1]"
    --metric "MI[${TEMPLATE_IMAGE},${MOVING_IMAGE},1,32,Regular,0.25]"
    --convergence "[1000x500x250x100,1e-6,10]"
    --shrink-factors "8x4x2x1"
    --smoothing-sigmas "3x2x1x0vox"
  )
fi

if [[ "${DO_NONLINEAR}" -eq 1 ]]; then
  REG_CMD+=(
    # SyN nonlinear
    --transform "SyN[0.1,3,0]"
    --metric "CC[${TEMPLATE_IMAGE},${MOVING_IMAGE},1,4]"
    --convergence "[100x70x50x20,1e-6,10]"
    --shrink-factors "8x4x2x1"
    --smoothing-sigmas "3x2x1x0vox"
  )
fi

REG_CMD+=(
  --verbose 1
)

###############################################################################
# Run antsRegistration
###############################################################################

echo "[INFO] Running antsRegistration..."
echo "[INFO] Template: ${TEMPLATE_IMAGE}"
echo "[INFO] Moving:   ${MOVING_IMAGE}"
echo "[INFO] Output prefix: ${OUT_PREFIX}"

"${REG_CMD[@]}"

###############################################################################
# Collect transforms for antsApplyTransforms
###############################################################################

# antsRegistration by default produces:
#   ${OUT_PREFIX}0GenericAffine.mat
#   ${OUT_PREFIX}1Warp.nii.gz (if nonlinear enabled)
#   ${OUT_PREFIX}1InverseWarp.nii.gz (if nonlinear enabled)

if [[ "${DO_NONLINEAR}" -eq 1 ]]; then
  TRANSFORMS+=("${OUT_PREFIX}1Warp.nii.gz" "${OUT_PREFIX}0GenericAffine.mat")
else
  TRANSFORMS+=("${OUT_PREFIX}0GenericAffine.mat")
fi

###############################################################################
# Apply transforms to label image (nearest neighbor)
###############################################################################

OUT_LABELS="${OUTPUT_DIR}/labels_in_template_space.nii.gz"

echo "[INFO] Applying transforms to label image..."
echo "[INFO] Labels:   ${LABEL_IMAGE}"
echo "[INFO] Output:   ${OUT_LABELS}"

antsApplyTransforms \
  -d "${DIM}" \
  -i "${LABEL_IMAGE}" \
  -r "${TEMPLATE_IMAGE}" \
  -o "${OUT_LABELS}" \
  -n NearestNeighbor \
  $(for t in "${TRANSFORMS[@]}"; do echo -t "${t}"; done)

echo "[INFO] Done. Registered labels written to: ${OUT_LABELS}"

echo "[INFO] Next step: convert these hippocampal labels into HippUnfold-compatible"
echo "[INFO] segmentation volumes (e.g., via a separate Python script) and then"
echo "[INFO] run HippUnfold on BIDS-structured data in ../data/bids/."

exit 0

