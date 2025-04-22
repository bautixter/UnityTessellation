using UnityEngine;

public class SeagullSpawner : MonoBehaviour
{
    public int seagullCount = 20;
    public float areaSize = 50f;
    public Material seagullMaterial;
    
    void Start()
    {
        for (int i = 0; i < seagullCount; i++)
        {
            CreateSeagull();
        }
    }
    
    void CreateSeagull()
    {
        GameObject seagull = new GameObject("Seagull");
        seagull.transform.parent = transform;
        
        // Posición aleatoria dentro del área
        Vector3 position = new Vector3(
            Random.Range(-areaSize, areaSize),
            Random.Range(5f, 20f),
            Random.Range(-areaSize, areaSize)
        );
        
        seagull.transform.position = position;
        
        // Añadir componente para movimiento
        SeagullMovement movement = seagull.AddComponent<SeagullMovement>();
        movement.speed = Random.Range(3f, 8f);
        movement.areaSize = areaSize;
        
        // Añadir MeshFilter y MeshRenderer
        MeshFilter mf = seagull.AddComponent<MeshFilter>();
        MeshRenderer mr = seagull.AddComponent<MeshRenderer>();
        mr.material = seagullMaterial;
        
        // Crear un mesh con un solo vértice (el shader de geometría lo expandirá)
        Mesh mesh = new Mesh();
        mesh.vertices = new Vector3[] { Vector3.zero };
        mesh.SetIndices(new int[] { 0 }, MeshTopology.Points, 0);
        mf.mesh = mesh;
    }
}