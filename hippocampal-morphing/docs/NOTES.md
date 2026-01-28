## Project Notes and References

This file is a lightweight place to collect links and design notes related to the hippocampal morphing project.

- **HippUnfold**
  - GitHub: https://github.com/khanlab/hippunfold
  - Use this for generating topologically consistent hippocampal surfaces for human and potentially other species (with adapted templates).

- **ANTs (Advanced Normalization Tools)**
  - Website: https://stnava.github.io/ANTs/
  - Used here for atlas-to-template registration (`register_labels.sh`).

- **Atlas / Template resources (examples)**
  - Allen Mouse Brain Atlas / CCF:
    - https://portal.brain-map.org/
  - Waxholm Space (WHS) mouse atlas:
    - https://www.nitrc.org/projects/whs-sd-atlas
  - CIVM resources:
    - e.g., search for "CIVM mouse brain atlas NIfTI"
  - ICBM 2009c Asymmetric NIfTI:
    - https://www.bic.mni.mcgill.ca/ServicesAtlases/ICBM152NLin2009
  - MBMv3 (Macaque Brain Mapping v3):
    - Search for "MBMv3 macaque atlas" and follow official links.

- **Unity Integration**
  - Place `Morpher.cs` in your Unity project's `Assets/Scripts/` folder.
  - Import OBJ meshes produced by `convert_gii_to_obj.py` into e.g. `Assets/Meshes/Hippocampus/`.
  - Attach `Morpher` to a GameObject with a `MeshFilter` and drive `Weights` via UI or AR logic.

