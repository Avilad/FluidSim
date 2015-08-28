//
//  FLSLiquidPostShader.m
//  FluidSim
//
//  Created by Avilad on 2/9/14.
//  Copyright (c) 2014 Avilad. All rights reserved.
//

#import "FLSLiquidPostShader.h"
#import "FLSShaderProcessor.h"

// Shaders
#define STRINGIFY(A) #A
#include "LiquidPost.vsh"
#include "LiquidPost.fsh"

@implementation FLSLiquidPostShader

- (void)loadShader
{
    
    // Program
    FLSShaderProcessor* shaderProcessor = [[FLSShaderProcessor alloc] init];
    self.program = [shaderProcessor BuildProgram:LiquidPostVS with:LiquidPostFS];
    
    // Attributes
    self.v_coord = glGetAttribLocation(self.program, "v_coord");
    
    // Uniforms
    self.fbo_texture = glGetUniformLocation(self.program, "fbo_texture");
    self.uScreenSize = glGetUniformLocation(self.program, "uScreenSize");
    self.uGravity = glGetUniformLocation(self.program, "uGravity");
    self.uShimmer = glGetUniformLocation(self.program, "uShimmer");
    
    self.uLook_BaseColor = glGetUniformLocation(self.program, "uLook_BaseColor");
    self.uLook_Clarity = glGetUniformLocation(self.program, "uLook_Clarity");
    self.uLook_Shimmer = glGetUniformLocation(self.program, "uLook_Shimmer");
    self.uLook_Foam = glGetUniformLocation(self.program, "uLook_Foam");
    
}

@end
