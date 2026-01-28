#!/usr/bin/env bash
#
# download_templates.sh
#
# Purpose:
#   Document and (where possible) download species templates and atlases
#   used for hippocampal morphing across human, macaque, marmoset, rat, and mouse.
#   Also sets up placeholders and README notes when manual download is required.
#
# Atlases / Templates (examples):
#   - Human:
#       * ICBM 2009c Asymmetric NIfTI (1 mm)
#       * HippUnfold templates (from khanlab/hippunfold)
#   - Mouse:
#       * Allen Mouse Brain Common Coordinate Framework (CCF)
#       * Waxholm Space (WHS)
#       * CIVM Mouse Brain Atlas
#   - Marmoset / Macaque:
#       * MBMv3 (Macaque Brain Mapping)
#       * Other species templates as available
#
# Usage:
#   bash download_templates.sh
#
# Notes:
#   - This script is intentionally conservative about direct downloads
#     because many resources are gated by licenses or portals.
#   - It prints URLs + instructions, and creates placeholder files in
#     ../data/raw/ to guide where you should place downloaded NIfTI files.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW_DIR="${ROOT_DIR}/data/raw"

mkdir -p "${RAW_DIR}"

info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }

create_placeholder() {
  local path="$1"
  local note="$2"
  if [[ ! -f "${path}" ]]; then
    info "Creating placeholder: ${path}"
    echo -e "${note}\n" > "${path}"
  else
    info "Placeholder already exists: ${path}"
  fi
}

###############################################################################
# Human: ICBM 2009c Asymmetric 1 mm
###############################################################################

info "Setting up ICBM 2009c Asymmetric (1mm) placeholders..."

ICBM_README="${RAW_DIR}/ICBM2009c_asym_1mm.README.txt"
create_placeholder "${ICBM_README}" \
"ICBM 2009c Asymmetric 1mm template

Suggested source:
  - ICBM 2009c Asymmetric template:
    https://www.bic.mni.mcgill.ca/ServicesAtlases/ICBM152NLin2009

Place the downloaded NIfTI files here, e.g.:
  - ICBM2009c_asym_1mm_T1.nii.gz
  - ICBM2009c_asym_1mm_brain.nii.gz

Ensure the file naming matches your registration + HippUnfold configuration."

###############################################################################
# HippUnfold templates
###############################################################################

info "Documenting HippUnfold template download..."

HIPPUNFOLD_README="${RAW_DIR}/hippunfold_templates.README.txt"
create_placeholder "${HIPPUNFOLD_README}" \
"HippUnfold templates and models

Official repository:
  - https://github.com/khanlab/hippunfold

Follow the installation instructions provided there. This pipeline expects
HippUnfold's default template + model directories to be installed in your
environment, not inside this repo.

You may optionally copy specific template surfaces or labelmaps into
../data/raw/ if you want all resources local to this project."

###############################################################################
# Mouse: Allen CCF, Waxholm, CIVM
###############################################################################

info "Setting up mouse atlas placeholders (Allen, Waxholm, CIVM)..."

MOUSE_README="${RAW_DIR}/mouse_atlases.README.txt"
create_placeholder "${MOUSE_README}" \
"Mouse brain templates and atlases

Allen Mouse Brain Common Coordinate Framework (CCF):
  - Portal: https://portal.brain-map.org/
  - Look for 'Allen Mouse Brain Atlas' and CCFv3 resources.

Waxholm Space (WHS):
  - Example: https://www.nitrc.org/projects/whs-sd-atlas

CIVM Mouse Brain Atlas:
  - Example: https://www.nitrc.org/projects/civm_rhesus_atlas (CIVM resources)

Place downloaded NIfTI files here, for example:
  - allen_ccf_mouse_T2.nii.gz
  - allen_ccf_mouse_labels.nii.gz
  - waxholm_mouse_T2.nii.gz
  - waxholm_mouse_labels.nii.gz
  - civm_mouse_T2.nii.gz
  - civm_mouse_labels.nii.gz

You are responsible for respecting all licenses and usage policies."

###############################################################################
# Macaque / Marmoset: MBMv3 and related
###############################################################################

info "Setting up macaque/marmoset atlas placeholders (MBMv3, etc.)..."

PRIMATE_README="${RAW_DIR}/primate_atlases.README.txt"
create_placeholder "${PRIMATE_README}" \
"Macaque and marmoset brain templates and atlases

MBMv3 (Macaque Brain Mapping v3):
  - See related publications and project pages for links.
  - Example keyword search: 'MBMv3 macaque brain atlas'

Marmoset atlases:
  - Example: 'Marmoset Brain Connectivity Atlas'

Place downloaded NIfTI template + label files here, for example:
  - macaque_MBMv3_T1.nii.gz
  - macaque_MBMv3_labels.nii.gz
  - marmoset_template_T1.nii.gz
  - marmoset_labels.nii.gz

Ensure consistent orientation and resolution for downstream ANTs registrations."

###############################################################################
# Notes and summary
###############################################################################

info "------------------------------------------------------------------"
info "Template/atlas placeholders created in: ${RAW_DIR}"
info "Now manually download the required NIfTI templates/atlases following"
info "the instructions in the *.README.txt files."
info "------------------------------------------------------------------"

exit 0

