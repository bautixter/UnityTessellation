using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AdaptativeTessellation : MonoBehaviour
{
    [Header("Tessellation Reference")]
    [SerializeField] private string tessellationUniform = "_TessellationUniform";

    [Header("Tessellation Parameters")]
    [SerializeField] private float maxTessellation = 15;
    [SerializeField] private float minTessellation = 2;
    [SerializeField] private float minDistance = 1;
    [SerializeField] private float maxDistance = 20;

    private Material material;

    void Start()
    {
        material = GetComponent<Renderer>().material;
    }

    void Update()
    {
        float distance = Vector3.Distance(Camera.main.transform.position, transform.position);
        float tessellation = Mathf.Clamp((maxDistance - minDistance) / (distance - minDistance), 0, 1);
        tessellation = Mathf.Lerp(minTessellation, maxTessellation, tessellation);
        material.SetFloat("_TessellationUniform", tessellation);
    }
}
