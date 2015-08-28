//
//  FLSShaderProcessor.h
//  FluidSim
//
//  Created by Avilad on 2/4/14.
//  Copyright (c) 2014 Avilad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface FLSShaderProcessor : NSObject

- (GLuint)BuildProgram:(const char*)vertexShaderSource with:(const char*)fragmentShaderSource;

@end