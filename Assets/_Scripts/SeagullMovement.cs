using UnityEngine;

public class SeagullMovement : MonoBehaviour
{
    public float speed = 5f;
    public float areaSize = 50f;
    private Vector3 target;
    private float changeTargetTime = 0f;
    
    void Update()
    {
        // Cambiar dirección periódicamente
        if (Time.time > changeTargetTime)
        {
            target = new Vector3(
                Random.Range(-areaSize, areaSize),
                Random.Range(5f, 20f),
                Random.Range(-areaSize, areaSize)
            );
            changeTargetTime = Time.time + Random.Range(2f, 5f);
        }
        
        // Moverse hacia el objetivo
        transform.position = Vector3.MoveTowards(transform.position, target, speed * Time.deltaTime);
        
        // Rotar hacia la dirección del movimiento
        if ((target - transform.position).magnitude > 0.1f)
        {
            transform.rotation = Quaternion.LookRotation(target - transform.position);
        }
    }
}