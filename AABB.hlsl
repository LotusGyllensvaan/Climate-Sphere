//Axis Aligned Bounding box
struct AABB {
    float3 min;
    float3 max;
};

//Struct for intersection between ray and AABB
struct AABBIntersectResult{
    float near;
    float far;
};

//Get intersection between AABB and ray
AABBIntersectResult intersectAABB(float3 rayOrigin, float3 rayDir, AABB box) {
    float3 tMin = (box.min - rayOrigin) / rayDir;
    float3 tMax = (box.max - rayOrigin) / rayDir;
    float3 t1 = min(tMin, tMax);
    float3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    AABBIntersectResult result;
    result.near = tNear;
    result.far = tFar;
    return result;
}

//Is ray origin inside AABB?
bool insideAABB(float3 rayOrigin, AABB box) {
    return all(rayOrigin <= box.max) && all(box.min < rayOrigin);
}

//Common functions:
//-----------------

//Inverse linear interpolation
float inverseLerp(float minValue, float maxValue, float v) {
    return (v - minValue) / (maxValue - minValue);
}

//Remap from one range to another
float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(inMin, inMax, v);
    return lerp(outMin, outMax, t);
}
