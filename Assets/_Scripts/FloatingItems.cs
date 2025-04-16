using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FloatingItems : MonoBehaviour
{
    public float HeightMovement = 0.3f;
    public float MoveSpeed = 0.1f;
    void Awake()
    {
        StartCoroutine(Float());
    }
    IEnumerator Float()
    {
        var currentHeight = transform.position.y;
        var targetHeight = transform.position.y + HeightMovement;
        while(currentHeight < targetHeight)
        {
            transform.position += new Vector3(0,MoveSpeed,0) * Time.deltaTime;
            currentHeight = transform.position.y;
            yield return null;
        }
        targetHeight = transform.position.y - HeightMovement;
        while(currentHeight > targetHeight)
        {
            transform.position -= new Vector3(0,MoveSpeed,0) * Time.deltaTime;
            currentHeight = transform.position.y;
            yield return null;
        }
        StartCoroutine(Float());
    }
}
