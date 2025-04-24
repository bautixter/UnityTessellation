using UnityEngine;

public class FishSpawner : MonoBehaviour
{
    public int fishCount = 20;
    public float planeWidth = 3f;
    public float planeHeight = 1f;
    public Material fishMaterial;
    
    void Start()
    {
        for (int i = 0; i < fishCount; i++)
        {
            Createfish();
        }
    }
    
    void Createfish()
    {
        GameObject fish = new GameObject("fish");
        fish.transform.parent = transform;
        
        float x = Random.Range(-planeWidth/2, planeWidth/2);
        float y = Random.Range(-planeHeight/2, planeHeight/2);
        
        // Forzar posición Z local a cero
        fish.transform.localPosition = new Vector3(x, y, 0f);
        fish.transform.rotation = transform.rotation;

        // Añadir MeshFilter y MeshRenderer
        MeshFilter mf = fish.AddComponent<MeshFilter>();
        MeshRenderer mr = fish.AddComponent<MeshRenderer>();
        mr.material = fishMaterial;
        
        // Crear un mesh con un solo vértice (el shader de geometría lo expandirá)
        Mesh mesh = new Mesh();
        mesh.vertices = new Vector3[] { Vector3.zero };
        mesh.SetIndices(new int[] { 0 }, MeshTopology.Points, 0);
        mesh.bounds = new Bounds(Vector3.zero, new Vector3(1, 1, 1));
        mf.mesh = mesh;

        fish.AddComponent<FishMovement>();
        fish.AddComponent<BoxCollider>();
        fish.AddComponent<Rigidbody>().isKinematic = true;
    }
}