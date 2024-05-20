//Unpacks flow speed from our ocean texture
void UnpackFlowSpeed_float(float4 textureData, float strength, out float3 flow)
{
    flow = textureData.xyz;
    flow.xy = flow.xy * 2.0 - 1.0;
    flow *= strength;
}