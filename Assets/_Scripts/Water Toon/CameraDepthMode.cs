using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraDepthMode : MonoBehaviour
{
    [SerializeField] DepthTextureMode _depthTextureMode;
    Camera _camera;
    void OnValidate()
    {
        InitCamera();
        SetCameraDepthTextureMode();
    }

    void Awake()
    {
        InitCamera();
        SetCameraDepthTextureMode();
    }

    void SetCameraDepthTextureMode()
    {
        _camera.depthTextureMode = _depthTextureMode;
    }

    void InitCamera()
    {
        if(_camera == null)
            _camera = GetComponent<Camera>();
    }
}
