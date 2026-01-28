using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Morpher
///
/// A simple mesh morphing component designed for cross-species
/// hippocampal surface visualization in Unity.
///
/// - Assumes all source meshes:
///     * Have identical vertex/triangle topology
///     * Differ only in vertex positions (and optionally normals)
/// - Operates on a MeshFilter's shared mesh at runtime.
///
/// Typical usage:
///   - Prepare species meshes (human, macaque, marmoset, rat, mouse)
///     as OBJ files converted from HippUnfold GIFTI outputs.
///   - Import them into Unity and assign them in the inspector.
///   - Use SetMorphWeight or SetMorphWeights to drive interpolation
///     (e.g., via UI sliders, animation, or an AR controller).
/// </summary>
[RequireComponent(typeof(MeshFilter))]
public class Morpher : MonoBehaviour
{
    [System.Serializable]
    public class SpeciesMesh
    {
        [Tooltip("Human-readable name, e.g. 'Human', 'Mouse', 'Macaque'.")]
        public string Label = "Species";

        [Tooltip("Mesh asset with identical topology to other species meshes.")]
        public Mesh Mesh;
    }

    [Header("Source Meshes (same topology)")]
    [Tooltip("Ordered list of species meshes (e.g. Human, Macaque, Marmoset, Rat, Mouse).")]
    public List<SpeciesMesh> SpeciesMeshes = new List<SpeciesMesh>();

    [Header("Morph Weights")]
    [Tooltip("Per-species weights. Should sum to 1 for pure interpolation, but this is not enforced.")]
    public List<float> Weights = new List<float>();

    [Header("Runtime Options")]
    [Tooltip("Recompute normals after each morph update.")]
    public bool RecalculateNormals = true;

    [Tooltip("Automatically normalize weights to sum to 1 on each update.")]
    public bool NormalizeWeights = true;

    private Mesh _workingMesh;
    private Vector3[] _baseVertices;
    private Vector3[] _workingVertices;

    private void Awake()
    {
        InitializeMesh();
    }

    private void Reset()
    {
        // Initialize some defaults if the component is added in the Editor.
        Weights.Clear();
    }

    /// <summary>
    /// Initialize the working mesh from the first species' mesh.
    /// All species must share the same vertex/triangle layout.
    /// </summary>
    private void InitializeMesh()
    {
        var mf = GetComponent<MeshFilter>();
        if (mf.sharedMesh == null)
        {
            Debug.LogWarning("[Morpher] No mesh found on MeshFilter. Assign at least one SpeciesMesh.");
            return;
        }

        // Clone the mesh so we don't overwrite the asset.
        _workingMesh = Instantiate(mf.sharedMesh);
        _workingMesh.name = mf.sharedMesh.name + " (MorpherWorkingCopy)";
        mf.sharedMesh = _workingMesh;

        _baseVertices = _workingMesh.vertices;
        _workingVertices = new Vector3[_baseVertices.Length];

        // Ensure weights length matches number of species.
        SyncWeightsLength();

        // Perform an initial update.
        ApplyMorph();
    }

    private void SyncWeightsLength()
    {
        while (Weights.Count < SpeciesMeshes.Count)
        {
            Weights.Add(0f);
        }

        if (Weights.Count > SpeciesMeshes.Count)
        {
            Weights.RemoveRange(SpeciesMeshes.Count, Weights.Count - SpeciesMeshes.Count);
        }
    }

    /// <summary>
    /// Set the weight for a particular species index.
    /// Optionally triggers an immediate morph update.
    /// </summary>
    public void SetMorphWeight(int index, float weight, bool updateNow = true)
    {
        if (index < 0 || index >= Weights.Count)
        {
            Debug.LogWarning($"[Morpher] Invalid index {index} for SetMorphWeight.");
            return;
        }

        Weights[index] = Mathf.Max(0f, weight);

        if (updateNow)
        {
            ApplyMorph();
        }
    }

    /// <summary>
    /// Replace all weights at once. Length must match SpeciesMeshes count.
    /// </summary>
    public void SetMorphWeights(IList<float> newWeights, bool updateNow = true)
    {
        if (newWeights == null || newWeights.Count != SpeciesMeshes.Count)
        {
            Debug.LogWarning("[Morpher] SetMorphWeights: weight count must match SpeciesMeshes count.");
            return;
        }

        Weights.Clear();
        Weights.AddRange(newWeights);

        if (updateNow)
        {
            ApplyMorph();
        }
    }

    /// <summary>
    /// Compute the blended vertex positions based on current weights.
    /// </summary>
    public void ApplyMorph()
    {
        if (_workingMesh == null)
        {
            InitializeMesh();
            if (_workingMesh == null) return;
        }

        SyncWeightsLength();

        if (NormalizeWeights)
        {
            NormalizeWeightsInPlace();
        }

        // Start from zeros; we'll accumulate weighted displacements.
        for (int i = 0; i < _workingVertices.Length; i++)
        {
            _workingVertices[i] = Vector3.zero;
        }

        // Blend across all species meshes.
        for (int s = 0; s < SpeciesMeshes.Count; s++)
        {
            float w = Weights[s];
            if (w <= 0f) continue;

            Mesh m = SpeciesMeshes[s].Mesh;
            if (m == null)
            {
                Debug.LogWarning($"[Morpher] Species '{SpeciesMeshes[s].Label}' has no mesh assigned.");
                continue;
            }

            if (m.vertexCount != _workingVertices.Length)
            {
                Debug.LogError($"[Morpher] Mesh vertex count mismatch for species '{SpeciesMeshes[s].Label}'. " +
                               $"Expected {_workingVertices.Length}, got {m.vertexCount}.");
                continue;
            }

            var v = m.vertices;
            for (int i = 0; i < _workingVertices.Length; i++)
            {
                _workingVertices[i] += v[i] * w;
            }
        }

        _workingMesh.vertices = _workingVertices;

        if (RecalculateNormals)
        {
            _workingMesh.RecalculateNormals();
        }

        _workingMesh.RecalculateBounds();
    }

    private void NormalizeWeightsInPlace()
    {
        float sum = 0f;
        for (int i = 0; i < Weights.Count; i++)
        {
            if (Weights[i] < 0f) Weights[i] = 0f;
            sum += Weights[i];
        }

        if (sum <= 0f)
        {
            // Avoid division by zero: fallback to first species if available.
            if (Weights.Count > 0)
            {
                Weights[0] = 1f;
                for (int i = 1; i < Weights.Count; i++)
                {
                    Weights[i] = 0f;
                }
            }
            return;
        }

        float inv = 1f / sum;
        for (int i = 0; i < Weights.Count; i++)
        {
            Weights[i] *= inv;
        }
    }
}

