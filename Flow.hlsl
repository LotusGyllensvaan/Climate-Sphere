//Distorts uvs according to a flow-vector
void FlowUVW_float(
    float2 uv, float2 flowVector, float2 jump,
    float flowOffset, float tiling, float time, bool flowB, out float3 uvw
)
{
    //If we blend between two flow textures their functions always equal 1.
    float phaseOffset = flowB ? 0.5 : 0.0;
    
    //Decimal part of seconds. This resets the flow-anim every second.
    float progress = frac(time + phaseOffset);
    
    //Distort uv in direction of flow vector
    uvw.xy = uv - flowVector * (progress + flowOffset);
    uvw.xy *= tiling;
    uvw.xy += phaseOffset;
    
    //Offset tex-pattern between phases (integer part of time * uv offset). Avoids directional bias.
    uvw.xy += (time - progress) * jump;
    
    //Function for blend weight.
    uvw.z = 1.0 - abs(1.0 - 2 * progress);
}