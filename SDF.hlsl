//Hollow sphere Signed Distance Function
float sdCutHollowSphere( float3 p, float r, float h, float t )
{
  // sampling independent computations (only depend on shape)
  float w = sqrt(r*r-h*h);
  
  // sampling dependant computations
  float2 q = float2( length(p.xz), p.y );
  return ((h*q.x<w*q.y) ? length(q-float2(w,h)) : 
                          abs(length(q)-r) ) - t;
}