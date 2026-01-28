## Hippocampal Morphing Pipeline

This repository scaffolds a **cross-species hippocampal morphing pipeline** targeting real‑time AR visualization in Unity.

The goal is to:
- **Download** species templates and atlases (Allen, Waxholm, MBMv3, CIVM, ICBM 2009c, etc.)
- **Register** atlas labels to templates using **ANTs**
- **Convert** hippocampal segmentations into **HippUnfold**-compatible format
- **Run HippUnfold** to generate topologically consistent hippocampal surfaces for multiple species
- **Convert** `*.gii` surfaces to `*.obj` for Unity
- **Morph meshes in Unity** using a reusable `Morpher` C# component.

This scaffold focuses on structure, reproducibility, and clear integration points rather than providing all data and heavy dependencies directly.

---

## Directory Layout

```text
hippocampal-morphing/
  data/
    raw/              # Raw template + atlas NIfTI files
    bids/             # BIDS-structured data for HippUnfold
    hippunfold/       # HippUnfold outputs (surfaces, QC, etc.)
    labels/           # Registered hippocampal labels per species

  meshes/
    gii/              # Input GIFTI hippocampal surfaces (from HippUnfold)
    obj/              # Exported OBJ meshes ready for Unity

  scripts/
    download_templates.sh   # Fetch templates + atlases + HippUnfold resources
    register_labels.sh      # ANTs registration + label transfer
    convert_gii_to_obj.py   # GIFTI → OBJ conversion for Unity
    run_hippunfold_example.sh  # (placeholder) Example HippUnfold invocation

  unity_export/
    Morpher.cs        # Unity C# script for cross-species hippocampal morphing

  docs/
    NOTES.md          # Additional notes / references (optional)
```

---

## Dependencies

- **Python 3.8+** with:
  - `nibabel`
  - `numpy`
- **HippUnfold** (see [khanlab/hippunfold](https://github.com/khanlab/hippunfold))
- **ANTs** (Advanced Normalization Tools) available as `antsRegistration`, `antsApplyTransforms`, etc.
- **FSL / MRtrix / FreeSurfer** (optional, depending on your exact HippUnfold pipeline)
- **Unity 2021+** (for AR / mesh morphing)

You can manage Python dependencies with a `venv` and a simple `requirements.txt` such as:

```text
nibabel
numpy
```

---

## Quickstart

From the repository root `hippocampal-morphing/`:

1. **Create data directories**

   ```bash
   mkdir -p data/raw data/bids data/hippunfold data/labels meshes/gii meshes/obj
   ```

2. **Download templates and atlases**

   This script documents canonical sources (Allen, Waxholm, MBMv3, CIVM, ICBM):

   ```bash
   cd scripts
   bash download_templates.sh
   ```

   - The script uses `curl`/`wget` **if direct download URLs are available**.
   - Where licensing or portal logins are required, it will:
     - Print instructions and relevant URLs.
     - Create placeholder files in `data/raw/` with `.README` notes.

3. **Register hippocampal labels with ANTs**

   Once you have template + atlas label images (e.g., Allen hippocampal label maps), run:

   ```bash
   cd scripts
   bash register_labels.sh \
     --template ../data/raw/mouse_template.nii.gz \
     --labels ../data/raw/mouse_labels.nii.gz \
     --output ../data/labels/mouse/
   ```

   See inline comments in `scripts/register_labels.sh` for species‑specific usage examples.

4. **Prepare BIDS data and run HippUnfold**

   - Organize subject structural images into `data/bids/` following BIDS.
   - Use HippUnfold’s own documentation for full options; a minimal example shell wrapper is provided in `scripts/run_hippunfold_example.sh` (placeholder).
   - HippUnfold will produce hippocampal surfaces (often `*.gii`) which should be copied or linked into `meshes/gii/`.

5. **Convert GIFTI to OBJ for Unity**

   Activate your Python environment and run:

   ```bash
   cd scripts
   python convert_gii_to_obj.py \
     --input ../meshes/gii/human_hippo.L.surf.gii \
     --output ../meshes/obj/human_hippo_L.obj
   ```

   Use the `--batch` option to convert multiple surfaces at once.

6. **Import into Unity and use `Morpher`**

   - Drag `meshes/obj/*.obj` into your Unity project (e.g., `Assets/Meshes/Hippocampus/`).
   - Copy `unity_export/Morpher.cs` into `Assets/Scripts/`.
   - Attach `Morpher` to a `GameObject` with a `MeshFilter` and assign the cross‑species meshes.
   - At runtime, control morphing via sliders, UI, or scripts (e.g., morph between human ↔ mouse).

---

## Running Linux Tools from Windows via WSL

The heavy neuroimaging tools (ANTs, HippUnfold) are best run inside **WSL (Linux)**, while Unity runs on native Windows.  
This repo includes a small PowerShell helper `windows_wsl_run.ps1` so you can stay in Windows and transparently execute commands in WSL.

From the project root `hippocampal-morphing/` (in PowerShell):

```powershell
# Download templates / create placeholders (inside WSL)
.\windows_wsl_run.ps1 "./scripts/download_templates.sh"

# Run ANTs label registration (inside WSL)
.\windows_wsl_run.ps1 "./scripts/register_labels.sh --template ./data/raw/mouse_template.nii.gz --labels ./data/raw/mouse_labels.nii.gz --output ./data/labels/mouse"

# Convert GIFTI to OBJ using Python in WSL
.\windows_wsl_run.ps1 "python ./scripts/convert_gii_to_obj.py --input ./meshes/gii/human_hippo.L.surf.gii --output ./meshes/obj/human_hippo_L.obj"
```

Requirements:
- WSL installed (e.g., Ubuntu) and configured with ANTs, HippUnfold, Python + `nibabel`/`numpy`.
- This repo located on a drive that appears in WSL as `/mnt/<drive>` (e.g., `C:\...` → `/mnt/c/...`).

You can adapt the `Command` string in `windows_wsl_run.ps1` calls for any script in this project.

---

## Notes on Atlases and Templates

This repo does **not** redistribute atlas data. Instead we provide:
- **Suggested sources** (URLs in `scripts/download_templates.sh` and `docs/NOTES.md`).
- **Placeholder filenames** in `data/raw/` to indicate expected file naming and orientation.

You are responsible for:
- Accepting the appropriate licenses (e.g., Allen Institute, CIVM, ICBM).
- Ensuring correct alignment/orientation and label conventions for your analyses.

---

## Extending the Pipeline

- Add species‑specific subfolders under:
  - `data/raw/<species>/`
  - `data/labels/<species>/`
  - `meshes/gii/<species>/`, `meshes/obj/<species>/`
- Customize `register_labels.sh` to include:
  - Species‑specific ANTs parameters
  - Multi‑stage registration (rigid + affine + nonlinear)
- Enhance `Morpher.cs` to:
  - Interpolate texture coordinates and normals
  - Synchronize with AR tracking
  - Use ScriptableObjects to define species sets and morph sequences.

This scaffold is intentionally minimal but structured to grow with your master’s project.

