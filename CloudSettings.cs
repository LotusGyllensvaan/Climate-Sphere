using System;
using UnityEngine;
using System.Collections;

//Sends data from camera to cloud-shader
public class CloudSettings : MonoBehaviour {

    //Get identifiers for shader properties. Needed to set them later. 
    static int
        meshBoundsMinId = Shader.PropertyToID("_MeshBoundsMin"),
        meshBoundsMaxId = Shader.PropertyToID("_MeshBoundsMax"),
        camUpId = Shader.PropertyToID("_CameraUp"),
        camForwardId = Shader.PropertyToID("_CameraForward"),
        camRightId = Shader.PropertyToID("_CameraRight"),
        fovId = Shader.PropertyToID("_Fov"),
        aspectRatioId = Shader.PropertyToID("_AspectRatio");

    //Initialize variables
    private Material material;

    [SerializeField]
    private Camera currentCamera;

    Transform cameraTransform;

    Bounds meshBounds;

    void Awake() {
        //Get material with cloud-shader
        material = GetComponent<MeshRenderer>().sharedMaterial;
    }

    void OnEnable() {
        //Get camera transform and mesh bounds
        cameraTransform = currentCamera.transform;
        meshBounds = GetComponent<MeshFilter>().mesh.bounds;
    }

    void Update() {
        //Check if transform of cloud gameObject has changed
        if (transform.hasChanged) {
            transform.hasChanged = false;

            //Set properties. Bounds are used for optimized raymarching.
            material.SetVector(meshBoundsMinId, meshBounds.min);
            material.SetVector(meshBoundsMaxId, meshBounds.max);
        }
        //Check if transform of camera has changed
        if (cameraTransform.hasChanged)
        {
            cameraTransform.hasChanged = false;

            //Set properties. (If we change fov, or aspect ratio this wont update unless we change the transform, to it assumes those are constant)
            material.SetFloat(fovId, currentCamera.fieldOfView * Mathf.Deg2Rad);
            material.SetFloat(aspectRatioId, currentCamera.aspect);
            material.SetVector(camUpId, currentCamera.transform.up.normalized);
            material.SetVector(camForwardId, currentCamera.transform.forward.normalized);
            material.SetVector(camRightId, currentCamera.transform.right.normalized);
        }

    }
}
