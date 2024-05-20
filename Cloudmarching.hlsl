#include "AABB.hlsl"
#include "SDF.hlsl"

const float CLOUD_FALLOFF = 5.0;
const float CLOUD_BASE_STRENGTH = 0.8;
const float CLOUD_DETAIL_STRENGTH = 0.2;
const float CLOUD_DENSITY = 0.5;


float3 GetTexCoord(float3 samplePos, float tileWidth){ 
    return frac(samplePos * (1.0 / max(tileWidth, 0.0000001)));
}

//The Henyey-Greenstein phase function for approximating scattering
float HenyeyGreenstein(float g, float mu) {
    float gg = g * g;
	return (1.0 / (4.0 * PI))  * ((1.0 - gg) / pow(1.0 + gg - 2.0 * g * mu, 1.5));
}

//Dual Henyey-Greenstein which is apparently a little bit better than just one. From what i understand it creates more backscattering.
float DualHenyeyGreenstein(float g, float costh) {
    return lerp(HenyeyGreenstein(-g, costh), HenyeyGreenstein(g, costh), 0.7);
}

//Calculates severa octaves of scattering to let more light through. Taken from: https://twitter.com/FewesW/status/1364629939568451587
float3 MultipleOctaveScattering(float density, float mu) {
    //Initialize variables
    float attenuation = 0.2;
    float contribution = 0.2;
    float phaseAttenuation = 0.5;

    float a = 1.0;
    float b = 1.0;
    float c = 1.0;
    float g = 0.85;
    //How many octaves
    const int scatteringOctaves = 4;
  
    float3 luminance = 0.0;

    UNITY_LOOP
    for (int i = 0.0; i < 4; i++) {
        //Phase function which approximates scattering 
        float phaseFunction = DualHenyeyGreenstein(0.3 * c, mu);
        //Apply beer-lamberts law
        float3 beers = exp(-density * float3(0.8, 0.8, 1.0) * a);

        //Add to luminance
        luminance += b * phaseFunction * beers;

        //Values for next octave
        a *= attenuation;
        b *= contribution;
        c *= (1.0 - phaseAttenuation);
    }
    return luminance;
}

float getHeightSignal(float3 posWS, float botRadius, float cloudLayerLenght){
        float relativePos = clamp(length(posWS) - botRadius, 0, cloudLayerLenght);
        float relativePosNormalized = relativePos / cloudLayerLenght;
        return 1 - pow(2 * relativePosNormalized - 1, 2);
}

//Marches from sample-position towards light source to calculate luminance
float3 CalculateLightEnergy(
    UnityTexture3D volumeTex, UnitySamplerState volumeSampler,
    float3 lightOrigin, float3 cameraOrigin, float3 lightDirection,
    float mu, float maxDistance, float tileWidth
) {
    //Initialize variables
    float stepLength = maxDistance / 12;
	float lightRayDensity = 0.0;
    float distAccumulated = 0.0;

    //March
    UNITY_LOOP
    for(int j = 0; j < 12; j++) {
        //March towards light origin by total distance accumulated so far
        float3 lightSamplePos = lightOrigin - lightDirection * distAccumulated;

        //Add density for every sample
        lightRayDensity += SAMPLE_TEXTURE3D(volumeTex, volumeSampler, GetTexCoord(lightSamplePos, tileWidth)).r * stepLength;

        //Travel along ray
        distAccumulated += stepLength;
    }

    //Calculate beers law and gorilla games powder effect for lighting approximation
    float3 beersLaw = MultipleOctaveScattering(lightRayDensity, mu);//exp(-lightRayDensity * float3(0.8, 0.8, 1.0));
    float3 powder = 1.0 - exp(-lightRayDensity * 2.0 * float3(0.8, 0.8, 1.0));

    //Combine both functions
	return beersLaw * lerp(2.0 * powder, float3(1.0, 1.0, 1.0), remap(mu, -1.0, 1.0, 0.0, 1.0));
}

struct ScatteringTransmittance {
    float3 scattering;
    float3 transmittance;
};

//Marches a ray using signed-distance fields through cloud and calculates light data using a perlin-worley FMB-noise texture
void Cloudmarch_float(
    float2 uv, float3 camUp, float3 camForward, float3 camRight, float fov, float aspectRatio,
    UnityTexture3D volumeTex, UnitySamplerState volumeSampler,
    float3 lightDir, float3 cloudColor, 
    float sunLightMult, float ambientStrength, float2 resolution, float tileWidth, float pixelDepth, float cloudDensity, float3 ambientColor, 
    float botRadius, float cloudLayerThickness, float easterEgg,
    out float3 scatteringOut, out float3 transmittanceOut
) {
    
    //Calculate ray origin and ray direction for each pixel
    float3 rayOrigin = _WorldSpaceCameraPos;
    float3 rayDir = 
        normalize(camForward + 
        tan(fov / 2.0) * aspectRatio * uv.x * camRight + 
        tan(fov / 2.0) * uv.y * camUp
    );

    //Axis Aligned Bounding Box of cloud.
    AABB cloudAABB;
    cloudAABB.min = -100;
    cloudAABB.max = 100;

    //Intersection of view ray and bounding box
    AABBIntersectResult rayCloudIntersection = 
        intersectAABB(rayOrigin, rayDir, cloudAABB);
    float distNearToFar = rayCloudIntersection.far - rayCloudIntersection.near;

    //Initialize Scattering & Transmittance
    ScatteringTransmittance result;
    result.scattering = 0.0;
    result.transmittance = float3(1.0, 1.0, 1.0);
    scatteringOut = result.scattering;
    transmittanceOut = result.transmittance;
    lightDir = normalize(lightDir);

    //Guard Clauses
    if (rayCloudIntersection.near >= rayCloudIntersection.far) {
        scatteringOut = result.scattering;
        transmittanceOut = result.transmittance;
        return;
    }

    //If camer inside cloud, begin raymarching immediately
    if (insideAABB(rayOrigin, cloudAABB)) {
        rayCloudIntersection.near = 0.0;
    }

    //Some lighting Values
    float mu = dot(rayDir, lightDir);
    float3 lightColor = 1.0;
    float3 sunlight = lightColor * sunLightMult;
    float3 ambient = 0.1 * sunlight;

    //Cloudmarching values
    const int NUM_COUNT = 16;
    const float CLOUD_STEPS_MIN = 16.0;
    float lqStepLength = distNearToFar / CLOUD_STEPS_MIN; 
    float hqStepLength = lqStepLength / float(NUM_COUNT);
    float numCloudSteps = 128;

    float distTravelled = rayCloudIntersection.near;

    int hqMarcherCountdown = 0;
    
    //Main raymarching loop
   UNITY_LOOP
    for (int i = 0.0; i < 164; i++) {
        //Dont continue raymarching after leaving AABB
        if (distTravelled > rayCloudIntersection.far) {
          break;
        }
        //Dont render clouds that are behind opaque geometry
        if(distTravelled > pixelDepth){
            break;
        }

        //Position on ray increases per iteration, according to its direction and origin
        float3 samplePos = rayOrigin + rayDir * distTravelled;
        //Signed distance field of a hollow sphere which incapsulates planet. (''easterEgg'' paramater is only for testing)
        float cloudSDF = sdCutHollowSphere(samplePos, botRadius, easterEgg, cloudLayerThickness);

        if (hqMarcherCountdown <= 0) {
            if (cloudSDF < hqStepLength) {
                //Hit cloud, start marching with smaller steps
                hqMarcherCountdown = NUM_COUNT;
                distTravelled += hqStepLength;
            } else {
                //Didnt hit cloud, continue sphere marching with SDF. 
                distTravelled += cloudSDF;
                continue;
            }
        }

        if (hqMarcherCountdown > 0) {
            hqMarcherCountdown--;
            //If inside cloud, calculate lighting
            if (cloudSDF < 0.0) {
                hqMarcherCountdown = NUM_COUNT;

                //Height signal which eases cloud towards top and bottom of cloud layer
                float heightSignal = getHeightSignal(samplePos, botRadius, cloudLayerThickness);
                //Density / extinction from a 3D perlin-worley FBM texture
                float extinction = SAMPLE_TEXTURE3D(volumeTex, volumeSampler, GetTexCoord(samplePos + _Time.y, tileWidth)).r * cloudDensity * heightSignal;

                if(extinction > 0.0001) {
                    float3 ambient = ambientColor * ambientStrength;
                    // Calculate luminance at point
                    float3 luminance = ambient + lightColor * sunLightMult * CalculateLightEnergy(
                            volumeTex, volumeSampler,
                            samplePos, rayOrigin, lightDir, mu, 25, tileWidth
                    );
                    //How much light gets through
                    float3 transmittance = exp(-extinction * hqStepLength * float3(0.8, 0.8, 1.0));
                    //Integrated scattering 
                    float3 integScatt = extinction * (luminance - luminance * transmittance) / extinction;
                    //Add result to output variables
                    result.scattering += result.transmittance * integScatt;
                    result.transmittance *= transmittance;
                    
                    //An opaque check
                    if (length(result.transmittance) <= 0.01) {
                        result.transmittance = 0.0;
                        break;
                    }

                }
            }
            //Travel along ray
            distTravelled += hqStepLength;
        }   
            //return outputs to shader
            scatteringOut = result.scattering;
            transmittanceOut = result.transmittance;
    }
}

