//
//  FLSLiquidParticleShader.m
//  FluidSim
//
//  Created by SlEePlEs5 on 2/4/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import "FLSLiquidParticleShader.h"
#import "FLSShaderProcessor.h"

// Shaders
#define STRINGIFY(A) #A
#include "LiquidParticle.vsh"
#include "LiquidParticle.fsh"

@implementation FLSLiquidParticleShader

- (void)loadShader
{
    
    // Program
    FLSShaderProcessor* shaderProcessor = [[FLSShaderProcessor alloc] init];
    self.program = [shaderProcessor BuildProgram:LiquidParticleVS with:LiquidParticleFS];
    
    // Attributes
    self.aPosition = glGetAttribLocation(self.program, "aPosition");
    self.aVelocity = glGetAttribLocation(self.program, "aVelocity");
    
    // Uniforms
    self.uProjectionMatrix = glGetUniformLocation(self.program, "uProjectionMatrix");
    self.uRetinaScale = glGetUniformLocation(self.program, "uRetinaScale");
    self.uTexture = glGetUniformLocation(self.program, "uTexture");
}

@end
