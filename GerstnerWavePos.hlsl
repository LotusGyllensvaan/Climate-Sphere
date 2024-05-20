
//Generates gerstner waves on a spehere by offsetting vertices.
void GerstnerWavePos_float(
    int waveCount, float r, float time, 
    float E0, float E1, 
    float steepnessModifier, float amplitudeModifier, float frequencyModifier, float speedModifier,
    float waveNormalAmount,
    float3 posOS, out float3 wavePosOut, out float3 waveNormalOut, out float3 waveTangentOut
) {
    
    //Array of wave origins. Actually really bad code. Should use a procedural method instead.
    float3 waveOrigins[32] = {
        float3(-0.1619928, 0.9119491, -0.3769709),
        float3(0.1105812, 0.9732841, -0.2012207),
        float3(0.7707617, -0.6355719, -0.04443739),
        float3(0.3209089, 0.5101104, -0.7980005),
        float3(0.7454543, 0.3830461, -0.5455032),
        float3(-0.6808109, 0.7211186, 0.1283919),
        float3(-0.1880471, -0.8120919, -0.5523994),
        float3(0.4551651, -0.6101402, 0.6485011),
        float3(-0.333277, 0.2270212, 0.915089),
        float3(0.2802557, -0.6873351, 0.6700949),
        float3(0.28855, -0.3664881, 0.8845481),
        float3(0.7210877, -0.4035063, 0.5632187),
        float3(0.4923631, -0.8554552, 0.1605464),
        float3(-0.5767431, -0.8121302, -0.08838558),
        float3(-0.2633412, 0.9245647, -0.2753755),
        float3(0.1005686, 0.9323032, -0.3474141),
        float3(-0.6397726, 0.198346, 0.7425294),
        float3(-0.02877277, -0.6565298, 0.7537511),
        float3(-0.4623024, -0.7731299, -0.4342194),
        float3(0.8073605, 0.5885007, -0.04284816),
        float3(-0.6477017, -0.3387604, -0.6824397),
        float3(-0.9775938, 0.1382187, 0.1587641),
        float3(-0.440169, 0.7067747, -0.5538239),
        float3(0.4486232, 0.893628, 0.01289321),
        float3(-0.5198023, -0.7911967, 0.3222008),
        float3(0.6993925, 0.7118253, -0.06445871),
        float3(-0.2178374, -0.6670894, 0.7124174),
        float3(-0.1329871, -0.7132935, -0.6881328),
        float3(-0.76563, 0.0365878, -0.6422398),
        float3(-0.8109073, -0.2203808, -0.54209),
        float3(-0.8024215, -0.4358954, -0.407572),
        float3(-0.8797503, -0.2256065, -0.4184986)
    };
    
    //Paramaters of each wave:
    //x = amplitude, y = frequency, z = speedModifier, w = steepness. 
    //Also really bad. Should use a fractal method, like with FBM noise.
    float4 waveParams[32] =
    {
        float4(1, 0.11, 1, 0.67),
        float4(1, 0.29, 2, 1.340423),
        float4(1, 0.29, 2, 0.79),
        float4(1, 0.15, 2, 0.79),
        float4(1, 0.13, 3, 1.4),
        float4(0.201, 0.02, 1, 0.62),
        float4(0.1899377, 0.5264885, 6.58772, 0.62),
        float4(0.1799552, 0.555694, 6.241491, 0.7482457),
        float4(0.1702233, 0.5874635, 5.903956, 0.87),
        float4(0.1607495, 0.6220861, 5.575367, 0.8368034),
        float4(0.1515414, 0.6598858, 5.255999, 0.60813),
        float4(0.1426075, 0.7012254, 4.94614, 0.9443506),
        float4(0.1339569, 0.746509, 4.646105, 0.8453608),
        float4(0.125599, 0.7961845, 4.356225, 1.219368),
        float4(0.1175443, 0.8507434, 4.076857, 0.7806263),
        float4(0.1098033, 0.9107199, 3.808371, 1.292248),
        float4(0.1023872, 0.9766847, 3.551155, 0.3549307),
        float4(0.09530749, 1.049235, 3.305606, 0.96),
        float4(0.08857545, 1.128981, 3.072114, 0.991442),
        float4(0.08220173, 1.216519, 2.851051, 0.8991863),
        float4(0.07619566, 1.312411, 2.642739, 1.329735),
        float4(0.07056407, 1.417152, 2.447415, 1.138855),
        float4(0.06530974, 1.531165, 2.265176, 0.6686733),
        float4(0.06042945, 1.654822, 2.09591, 0.586866),
        float4(0.05591126, 1.788548, 1.939203, 0.4323999),
        float4(0.05173133, 1.933065, 1.794228, 1.064147),
        float4(0.04784992, 2.089868, 1.659607, 0.7897528),
        float4(0.04420675, 2.262098, 1.533249, 0.4979175),
        float4(0.04071499, 2.456098, 1.412142, 1.09372),
        float4(0.03725252, 2.684382, 1.292051, 1.334856),
        float4(0.03364624, 2.9721, 1.166972, 1.149004),
        float4(0.02963753, 3.3741, 1.027936, 0.8651988),
    };
    
    //Normalized object-space position
    float3 v = normalize(posOS);
    
    //Initialize variables
    float sinPart = 0.0;
    float3 cosPart = float3(0.0, 0.0, 0.0);
    
    float sinPartNormal = 0.0;
    float3 cosPartNormal = float3(0.0, 0.0, 0.0);
    
    float3 waveTangent = float3(0.0, 0.0, 0.0);
    
    //Equation retrieved from: https://cescg.org/wp-content/uploads/2018/04/Michelic-Real-Time-Rendering-of-Procedurally-Generated-Planets-2.pdf
    //Goes over each wave, calculating vertex offsets, normals, and tangents for lighting. 
    for (int i = 0; i < waveCount; i++)
    {
        //Normalized direction from ocean-sphere center to origin of the wave
        float3 oi = normalize(waveOrigins[i]);

        //Initialize wave paramaters
        float ai = waveParams[i].x * amplitudeModifier;
        float wi = waveParams[i].y * frequencyModifier;
        float pi = waveParams[i].z * speedModifier;

        //Prevents gerstner waves from folding in on themselves
        float steepnessDamping =
            smoothstep(1.0 - abs(dot(v, oi)), E0, E1);
        float qi = waveParams[i].w * steepnessDamping * steepnessModifier;

        //The distance from the wave-origin to the vertex
        float li = acos(dot(v, oi)) * r;

        //Tangent-plane wave direction
        float3 di = cross(v, cross((v - oi), v));


        //Gerstner wave function projected onto a sphere
        //Positions:
        sinPart += ai * sin(wi * li + pi * time);
        cosPart += qi * ai * cos(wi * li + pi * time) * di;
        
        //Normals:
        sinPartNormal += qi * ai * wi * sin(wi * li + pi * time);
        cosPartNormal += di * ai * wi * cos(wi * li + pi * time);
        
        //Tangents:
        float3 crossDIV = cross(di, v);
        waveTangent += crossDIV / length(crossDIV);
    }
    
    //Return values to vertex-shader
    wavePosOut = (v * r) + (v * sinPart) + cosPart;
    float3 waveNormal = v - (v * sinPartNormal) - cosPartNormal;
    waveNormalOut = normalize(lerp(v, waveNormal, waveNormalAmount));
    waveTangentOut = normalize(waveTangent);
}