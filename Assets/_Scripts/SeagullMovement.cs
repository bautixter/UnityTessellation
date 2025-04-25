using UnityEngine;

public class SeagullMovement : MonoBehaviour
{
    public float speed = 5f;
    public float areaSize = 50f;
    public float minHeight = 5f;
    public float maxHeight = 20f;
    
    private Vector3 target;
    private float changeTargetTime = 0f;
    private const float arrivalThreshold = 1.0f;
    
    void Start()
    {
        SetNewRandomTarget();
    }
    
    void Update()
    {
        if (Time.time > changeTargetTime || Vector3.Distance(transform.position, target) < arrivalThreshold)
        {
            SetNewRandomTarget();
        }
        
        transform.position = Vector3.MoveTowards(transform.position, target, speed * Time.deltaTime);
        
        Vector3 direction = target - transform.position;
        if (direction.magnitude > 0.1f)
        {
            transform.rotation = Quaternion.Slerp(transform.rotation, 
                                                Quaternion.LookRotation(direction), 
                                                Time.deltaTime * 4.0f);
        }
    }
    
    private void SetNewRandomTarget()
    {
        Vector3 newTarget;
        float distanceToTarget;
        int attemptCount = 0;
        
        do
        {
            newTarget = new Vector3(
                Random.Range(-areaSize, areaSize),
                Random.Range(minHeight, maxHeight),
                Random.Range(-areaSize, areaSize)
            );
            distanceToTarget = Vector3.Distance(transform.position, newTarget);
            attemptCount++;
        } 
        while (distanceToTarget < areaSize * 0.3f && attemptCount < 5); // Asegurar que no sea muy cercana
        
        target = newTarget;
        changeTargetTime = Time.time + Random.Range(3f, 7f); // Tiempo máximo hasta el próximo cambio
    }
}