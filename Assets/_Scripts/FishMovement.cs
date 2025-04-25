using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FishMovement : MonoBehaviour
{
    public float speed = 1f;
    public float maxBounceAngle = 90f; // Ángulo máximo para el rebote aleatorio
    private Transform sphereTransform; // El transform de la esfera que contiene a los peces
    private float sphereRadius; // Radio de la esfera
    private Vector3 lastPosition; // Para detectar si el pez está atascado

    private void Start()
    {
        // Buscar la esfera trigger con tag "fishCol"
        GameObject sphereObj = GameObject.FindGameObjectWithTag("fishCol");
        if (sphereObj != null)
        {
            SphereCollider sphereCollider = sphereObj.GetComponent<SphereCollider>();
            if (sphereCollider != null && sphereCollider.isTrigger)
            {
                sphereTransform = sphereObj.transform;
                sphereRadius = sphereCollider.radius * Mathf.Max(
                    sphereTransform.lossyScale.x,
                    Mathf.Max(sphereTransform.lossyScale.y, sphereTransform.lossyScale.z)
                );
            }
        }
        
        // Comprobar si el pez ya está cerca o fuera de los bordes al iniciar
        CheckAndFixInitialPosition();
        
        // Inicializar la última posición conocida
        lastPosition = transform.position;
        
        // Iniciar la detección de atasco
        StartCoroutine(DetectAndFixStuckFish());
    }

    private void CheckAndFixInitialPosition()
    {
        if (sphereTransform != null)
        {
            float distanceToCenter = Vector3.Distance(transform.position, sphereTransform.position);
            
            // Si el pez está demasiado cerca del borde al iniciar, reposicionarlo
            if (distanceToCenter >= sphereRadius * 0.9f)
            {
                // Mover el pez más hacia el interior de la esfera
                Vector3 directionToCenter = (sphereTransform.position - transform.position).normalized;
                Vector3 newPosition = sphereTransform.position - directionToCenter * (sphereRadius * 0.7f);
                
                // Mantener la altura Y
                newPosition.y = transform.position.y;
                
                // Aplicar la nueva posición
                transform.position = newPosition;
                
                // Dar una orientación aleatoria inicial en el plano horizontal
                float randomYRotation = Random.Range(0f, 360f);
                transform.rotation = Quaternion.Euler(0, randomYRotation, 0);
            }
        }
    }

    // Corrutina para detectar y arreglar peces atascados
    private IEnumerator DetectAndFixStuckFish()
    {
        while (true)
        {
            yield return new WaitForSeconds(1.0f);
            
            // Si el pez apenas se ha movido, probablemente esté atascado
            if (Vector3.Distance(transform.position, lastPosition) < 0.1f)
            {
                BounceInsideSphere();
            }
            
            lastPosition = transform.position;
        }
    }

    // Update is called once per frame
    void Update()
    {
        transform.position += transform.forward * speed * Time.deltaTime;
        
        // Si tenemos referencia a la esfera, comprobar si el pez está a punto de salir
        if (sphereTransform != null)
        {
            float distanceToCenter = Vector3.Distance(transform.position, sphereTransform.position);
            
            // Si está cerca del borde o fuera, hacer rebotar
            if (distanceToCenter >= sphereRadius * 0.95f)
            {
                BounceInsideSphere();
            }
        }
    }

    void OnTriggerExit(Collider other)
    {
        // Si el pez sale del trigger de la esfera, hacerlo rebotar hacia dentro
        if (other.isTrigger && other.GetComponent<SphereCollider>() != null)
        {
            BounceInsideSphere();
            
            // Asegurar que la referencia esté guardada
            if (sphereTransform == null)
            {
                sphereTransform = other.transform;
                sphereRadius = other.GetComponent<SphereCollider>().radius * Mathf.Max(
                    sphereTransform.lossyScale.x, 
                    Mathf.Max(sphereTransform.lossyScale.y, sphereTransform.lossyScale.z)
                );
            }
        }
    }
    
    private void BounceInsideSphere()
    {
        if (sphereTransform == null) return;
        
        // Calcular dirección desde la posición del pez hacia el centro de la esfera
        Vector3 directionToCenter = (sphereTransform.position - transform.position).normalized;
        
        // Proyectar la dirección en el plano XZ (horizontal)
        Vector3 horizontalDirection = new Vector3(directionToCenter.x, 0, directionToCenter.z).normalized;
        
        // Añadir una rotación aleatoria solo en el eje Y (alrededor del eje vertical)
        float randomAngleY = Random.Range(-maxBounceAngle, maxBounceAngle);
        
        Vector3 newDirection = Quaternion.Euler(0, randomAngleY, 0) * horizontalDirection;
        
        // Asegurar que el pez mira en la nueva dirección
        transform.forward = newDirection;
        
        // Calcular la posición horizontal respecto al centro
        Vector3 horizontalOffset = new Vector3(
            transform.position.x - sphereTransform.position.x,
            0,
            transform.position.z - sphereTransform.position.z
        );
        
        // Si el offset es demasiado pequeño (pez muy cerca del centro vertical), darle una dirección aleatoria
        if (horizontalOffset.magnitude < 0.1f)
        {
            horizontalOffset = new Vector3(Random.Range(-1f, 1f), 0, Random.Range(-1f, 1f)).normalized;
        }
        else
        {
            horizontalOffset = horizontalOffset.normalized;
        }
        
        // Preservar la altura Y original
        float currentY = transform.position.y;
        
        // Colocar al pez claramente dentro de la esfera (70% del radio para evitar problemas de precisión)
        transform.position = sphereTransform.position + horizontalOffset * (sphereRadius * 0.7f);
        transform.position = new Vector3(transform.position.x, currentY, transform.position.z);
        
        // Añadir una pequeña velocidad inicial en la nueva dirección
        Rigidbody rb = GetComponent<Rigidbody>();
        if (rb != null)
        {
            rb.velocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }
    }
}