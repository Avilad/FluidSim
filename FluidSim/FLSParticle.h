//
//  FLSParticle.h
//  FluidSim
//
//  Created by SlEePlEs5 on 1/28/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "FLSGlobals.h"

@interface FLSParticle : NSObject {
    
    @public float distances[MAX_PARTICLES];
    @public int neighbors[MAX_PARTICLES];
    
    @public GLKVector2 position;
    @public GLKVector2 velocity;
    @public BOOL alive;
    @public int index;
    
    @public int neighborCount;
    @public int ci;
    @public int cj;
    
    @private CGSize contentSize;
    
}

- (id)initWithFile:(NSString *)fileName effect:(GLKBaseEffect *)effect;
- (void)render;

@end
