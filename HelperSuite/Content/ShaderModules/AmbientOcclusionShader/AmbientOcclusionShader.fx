﻿/*The MIT License(MIT)

Copyright(c) 2017 by kosmonautgames

Parts of the SSAO Implementation:
Copyright(c) 2014 Sam Hardeman, NHTV University of Applied Sciences

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files(the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions :

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Variables

float2 Resolution = float2(1280, 800); 
float2 InverseResolution = float2(1.0f / 1280.0f, 1.0f / 800.0f);

float3 FrustumCorners[4]; //In Viewspace!

Texture2D TargetMap;
Texture2D DepthMap;

int Samples = 8;
float Strength = 1;
float SampleRadius = 1.0f;
const float PI = 3.14159265359;

SamplerState texSampler
{
	Texture = <DepthMap>;
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	Mipfilter = POINT;
};

SamplerState PointSampler
{
	Texture = <TargetMap>;
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	Mipfilter = POINT;
};

SamplerState LinearSampler
{
	Texture = <TargetMap>;
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	Mipfilter = POINT;
};


////////////////////////////////////////////////////////////////////////////
//  STRUCT DEFINITIONS

struct VertexShaderInput
{
	float3 Position : POSITION0;
	float2 TexCoord : TEXCOORD0;
};

struct VertexShaderOutput
{
	float4 Position : POSITION0;
	float2 TexCoord : TEXCOORD0;
	float3 ViewRay : TEXCOORD1;
};

struct VertexShaderOutputBlur
{
	float4 Position : POSITION0;
	float2 TexCoord : TEXCOORD0;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  FUNCTION DEFINITIONS

float3 GetFrustumRay(float2 texCoord)
{
	float index = texCoord.x + (texCoord.y * 2);
	return FrustumCorners[index];
}

float3 GetFrustumRay2(float2 texCoord)
{
	float3 x1 = lerp(FrustumCorners[0], FrustumCorners[1], texCoord.x);
	float3 x2 = lerp(FrustumCorners[2], FrustumCorners[3], texCoord.x);
	float3 outV = lerp(x1, x2, texCoord.y);
	return outV;
}


//  DEFAULT LIGHT SHADER FOR MODELS
VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
	VertexShaderOutput output;
	output.Position = float4(input.Position, 1);
	//align texture coordinates
	output.TexCoord = input.TexCoord;
	output.ViewRay = GetFrustumRay2(input.TexCoord);
	return output;
}

VertexShaderOutputBlur VertexShaderBlurFunction(VertexShaderInput input)
{
	VertexShaderOutputBlur output;
	output.Position = float4(input.Position, 1);
	//align texture coordinates
	output.TexCoord = input.TexCoord;
	return output;
}


float3 randomNormal(float2 tex)
{
	float noiseX = (frac(sin(dot(tex, float2(15.8989f, 76.132f) * 1.0f)) * 46336.23745f));
	float noiseY = (frac(sin(dot(tex, float2(11.9899f, 62.223f) * 2.0f)) * 34748.34744f));
	float noiseZ = (frac(sin(dot(tex, float2(13.3238f, 63.122f) * 3.0f)) * 59998.47362f));
	return normalize(float3(noiseX, noiseY, noiseZ));
}

float3 getPosition(float2 texCoord)
{
	float linearDepth = DepthMap.SampleLevel(texSampler, texCoord, 0).r;
	return GetFrustumRay2(texCoord) * linearDepth;
}


float GTAOFastSqrt(float x)
{
	// [Drobot2014a] Low Level Optimizations for GCN
	return asfloat(0x1FBD1DF5 + (asint(x) >> 1));
}

// Activion 2016 : Jorge Jimenez presentation on GTAO
float GTAOFastAcos(float x)
{
	float res = -0.156583 * abs(x) + PI / 2.0;
	res *= GTAOFastSqrt(1.0 - abs(x));
	return x >= 0 ? res : PI - res;
}

float fastlength(float3 vec)
{
	return GTAOFastSqrt(dot(vec, vec));
}

//float weightFunction(float3 vec3, float radius)
//{
//	// NVIDIA's weighting function
//	return 1.0 - pow(length(vec3) / radius, 2.0);
//}

float weightFunction(float len, float radius)
{
	// NVIDIA's weighting function
	return 1.0 - pow(len / radius, 2.0);
}


float4 PixelShaderFunction(VertexShaderOutput input) : SV_Target
{
	const float3 kernel[] =
	{
		float3(0.2024537f, 0.841204f, -0.9060141f),
		float3(-0.2200423f, 0.6282339f, -0.8275437f),
		float3(-0.7578573f, -0.5583301f, 0.2347527f),
		float3(-0.4540417f, -0.252365f, 0.0694318f),
		float3(0.3677659f, 0.1086345f, -0.4466777f),
		float3(0.8775856f, 0.4617546f, -0.6427765f),
		float3(-0.8433938f, 0.1451271f, 0.2202872f),
		float3(-0.4037157f, -0.8263387f, 0.4698132f),
		float3(0.7867433f, -0.141479f, -0.1567597f),
		float3(0.4839356f, -0.8253108f, -0.1563844f),
		float3(0.4401554f, -0.4228428f, -0.3300118f),
		float3(0.0019193f, -0.8048455f, 0.0726584f),
		float3(-0.0483353f, -0.2527294f, 0.5924745f),
		float3(-0.4192392f, 0.2084218f, -0.3672943f),
		float3(-0.6657394f, 0.6298575f, 0.6342437f),
		float3(-0.0001783f, 0.2834622f, 0.8343929f),
		float3(0.5381, 0.1856,-0.4319), float3(0.1379, 0.2486, 0.4430),
		float3(0.3371, 0.5679,-0.0057), float3(-0.6999,-0.0451,-0.0019),
		float3(0.0689,-0.1598,-0.8547), float3(0.0560, 0.0069,-0.1843),
		float3(-0.0146, 0.1402, 0.0762), float3(0.0100,-0.1924,-0.0344),
		float3(-0.3577,-0.5301,-0.4358), float3(-0.3169, 0.1063, 0.0158),
		float3(0.0103,-0.5869, 0.0046), float3(-0.0897,-0.4940, 0.3287),
		float3(0.7119,-0.0154,-0.0918), float3(-0.0533, 0.0596,-0.5411),
		float3(0.0352,-0.0631, 0.5460), float3(-0.4776, 0.2847,-0.0271)
	};

	const float clampMax = 0.1f; //0.2*0.2
	const float searchSteps = 4.0f;
	const float rcpSearchSteps = 0.25f;

	float2 texCoord = float2(input.TexCoord);

	////get normal data from the NormalMap
	//float4 normalData = NormalMap.Sample(texSampler, texCoord);
	////tranform normal back into [-1,1] range
	//
	float4 normalstruct = DepthMap.Sample(texSampler, texCoord);
	float linearDepth = normalstruct.x;

	if (linearDepth > 0.99999f)
	{
		return float4(0, 1, 1, 1);
	}
	float3 viewRay = GetFrustumRay2(texCoord);
	float3 currentPos = viewRay * linearDepth;

	float3 currentNormal = 2.0f * normalstruct.yzw - 1.0f; //normalize(cross(ddy(currentPos), ddx(currentPos))); // decode(normalData.xyz); //2.0f * normalData.xyz - 1.0f;    //could do mad
	
	//alternative 
	//currentPos = getPosition(texCoord);

	float currentDistance = -currentPos.z;

	float2 aspectRatio = float2(min(1, Resolution.y / Resolution.x), min(1.0f, Resolution.x / Resolution.y));

	float2 texelSize = InverseResolution;

	float amount = 1.0;

	float3 noise = randomNormal(texCoord);

	//HBAO 2 dir
	[loop]
	for (int i = 0; i < Samples / 2; i++)
	{
		float3 kernelVec = reflect(kernel[i], noise);
		kernelVec.xy *= aspectRatio;


		float radius = SampleRadius * (kernelVec.z + 1.01f);

		float2 kernelVector = (kernelVec.xy / currentDistance) * radius;

		//make it at least one pixel
		if (texelSize.x > abs(kernelVector.x * rcpSearchSteps))
		{
			kernelVector *= texelSize.x / kernelVector.x * searchSteps;
		}
		if (texelSize.y > abs(kernelVector.y * rcpSearchSteps))
		{
			kernelVector *= texelSize.y / kernelVector.y * searchSteps;
		}

		//clamp to 0,1
		kernelVector = saturate(kernelVector + texCoord) - texCoord;

		//clamp
		float length = GTAOFastSqrt(dot(kernelVector, kernelVector));

		float diff = length - clampMax;
		//max
		if (diff > 0)
		{
			float factor = clampMax / length;

			kernelVector *= factor;

			radius *= factor;
		}


		float biggestAnglePos = 0.3f;

		float biggestAngleNeg = 0.3f;

		float wAO = 0.0;

		float3 sampleVec;
		float sampleVecLength;
		float sampleAngle;

		[loop]
		for (int b = 1; b <= searchSteps; b++)
		{
			sampleVec = getPosition(texCoord + kernelVector * b / searchSteps) - currentPos;

			sampleVecLength = fastlength(sampleVec);

			sampleAngle = dot(sampleVec / sampleVecLength, currentNormal);

			//sampleAngle *= step(0.3, sampleAngle);

			[branch]
			if (sampleAngle > biggestAnglePos)
			{
				wAO += saturate(weightFunction(sampleVecLength, radius ) * (sampleAngle - biggestAnglePos));

				biggestAnglePos = sampleAngle;
			}

		}

		[loop]
		for (int b = 1; b <= searchSteps; b++)
		{
			sampleVec = getPosition(texCoord - kernelVector * b / searchSteps) - currentPos;

			sampleVecLength = fastlength(sampleVec);

			sampleAngle = dot(sampleVec / sampleVecLength, currentNormal);

			//sampleAngle *= step(0.3, sampleAngle);

			[branch]
			if (sampleAngle > biggestAngleNeg)
			{
				wAO += saturate(weightFunction(sampleVecLength, radius) * (sampleAngle - biggestAngleNeg));

				biggestAngleNeg = sampleAngle;
			}
		}

		/*biggestAngle = wAO;
		*/
		/*biggestAngle = max(0, biggestAngle);
		*/
		/*
		wAO = max(0, wAO);*/

		amount -= wAO / Samples *Strength;
	}

	/*float diff = amount - 0.5f;
	diff *= Strength;

	amount = saturate(0.5f + diff);
	*/
	return float4(amount, linearDepth, amount, 1);
}



float4 BilateralBlurVertical(VertexShaderOutputBlur input) : SV_TARGET
{
	const uint numSamples = 9;
	const uint centerSample = 5;
	const float samplerOffsets[numSamples] =
	{ -4.0f, -3.0f, -2.0f, -1.0f, 0.0f, 1.0f, 2.0f, 3.0f, 4.0f };
	const float gaussianWeights[numSamples] =
	{
		0.055119, 0.081029, 0.106701, 0.125858, 0.13298, 0.125858, 0.106701, 0.081029, 0.055119
	};
	const uint numSamples2 = 4;
	const float samplerOffsets2[numSamples2] =
	{ -7.5f, -5.5f, 5.5f, 7.5f };
	const float gaussianWeights2[numSamples2] =
	{
		0.012886, 0.051916, 0.051916, 0.012886,
	};

	//Store depth in g
	float2 centerStruct = TargetMap.SampleLevel(PointSampler, input.TexCoord, 0).rg;
	float centerValue = centerStruct.r;
	//float centerDepth = centerStruct.g;
	float centerDepth = DepthMap.SampleLevel(PointSampler, input.TexCoord, 0).r;

	//fullres
	float texelsize = InverseResolution.x;

	float weightSum = gaussianWeights[centerSample];
	float result = centerValue * weightSum;

	[unroll]
	for (uint i = 0; i < numSamples; ++i)
	{
		//Do not compute for mid sample
		if (i == centerSample) continue;

		float2 sampleOffset = float2(texelsize * samplerOffsets[i],0);
		float2 samplePos = input.TexCoord + sampleOffset;

		float2 sampleStruct = TargetMap.SampleLevel(PointSampler, samplePos, 0).rg;

		float weight = (1.0f / (0.0001f + abs(centerDepth - sampleStruct.g))) * gaussianWeights[i];

		result += sampleStruct.r * weight;

		weightSum += weight;
	}

	[unroll]
	for (uint j = 0; j < numSamples2; ++j)
	{
		float2 sampleOffset = float2(texelsize * samplerOffsets2[j],0);
		float2 samplePos = input.TexCoord + sampleOffset;

		float2 sampleStruct = TargetMap.SampleLevel(LinearSampler, samplePos, 0).rg;

		float weight = (1.0f / (0.0001f + abs(centerDepth - sampleStruct.g))) * gaussianWeights2[j];

		result += sampleStruct.r * weight;

		weightSum += weight;
	}

	result /= weightSum;

	return float4(result, centerDepth, 0, 0);
}


float4 BilateralBlurHorizontal(VertexShaderOutputBlur input) : SV_TARGET
{
	const uint numSamples = 9;
	const uint centerSample = 5;
	const float samplerOffsets[numSamples] =
	{ -4.0f, -3.0f, -2.0f, -1.0f, 0.0f, 1.0f, 2.0f, 3.0f, 4.0f };
	const float gaussianWeights[numSamples] =
	{
		0.055119, 0.081029, 0.106701, 0.125858, 0.13298, 0.125858, 0.106701, 0.081029, 0.055119
	};
	const uint numSamples2 = 4;
	const float samplerOffsets2[numSamples2] =
	{ -7.5f, -5.5f, 5.5f, 7.5f };
	const float gaussianWeights2[numSamples2] =
	{
		0.012886, 0.051916, 0.051916, 0.012886,
	};

	//Store depth in g
	float2 centerStruct = TargetMap.SampleLevel(PointSampler, input.TexCoord, 0).rg;
	float centerValue = centerStruct.r;
	//float centerDepth = centerStruct.g;
	float centerDepth = DepthMap.SampleLevel(PointSampler, input.TexCoord, 0).r;

	//fullres
	float texelsize = InverseResolution.y * 0.5f ;

	float weightSum = gaussianWeights[centerSample];
	float result = centerValue * weightSum;

	[unroll]
	for (uint i = 0; i < numSamples; ++i)
	{
		//Do not compute for mid sample
		if (i == centerSample) continue;

		float2 sampleOffset = float2(0,texelsize * samplerOffsets[i]);
		float2 samplePos = input.TexCoord + sampleOffset;

		float2 sampleStruct = TargetMap.SampleLevel(PointSampler, samplePos, 0).rg;

		float weight = (1.0f / (0.0001f + abs(centerDepth - sampleStruct.g))) * gaussianWeights[i];

		result += sampleStruct.r * weight;

		weightSum += weight;
	}

	[unroll]
	for (uint j = 0; j < numSamples2; ++j)
	{
		float2 sampleOffset = float2(0,texelsize * samplerOffsets2[j]);
		float2 samplePos = input.TexCoord + sampleOffset;

		float2 sampleStruct = TargetMap.SampleLevel(LinearSampler, samplePos, 0).rg;

		float weight = (1.0f / (0.0001f + abs(centerDepth - sampleStruct.g))) * gaussianWeights2[j];

		result += sampleStruct.r * weight;

		weightSum += weight;
	}

	result /= weightSum;

	return float4(result, centerDepth, 0, 0);
}



technique SSAO
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 VertexShaderFunction();
		PixelShader = compile ps_4_0 PixelShaderFunction();
	}
}

technique BilateralVertical
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 VertexShaderBlurFunction();
		PixelShader = compile ps_4_0 BilateralBlurVertical();
	}
}

technique BilateralHorizontal
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 VertexShaderBlurFunction();
		PixelShader = compile ps_4_0 BilateralBlurHorizontal();
	}
}
