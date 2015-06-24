//
//  FLSLiquid.h
//  FluidSim
//
//  Created by SlEePlEs5 on 2/4/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

const float scale = 64.0f;

typedef NS_ENUM(NSInteger, FLSTouchOperation) {
    FLSTouchDoNothing,
    FLSTouchAddFluid,
    FLSTouchRemoveFluid,
    FLSTouchFlingFluid
};

@interface FLSLiquid : NSObject

-(id)initWithScreenSize:(GLKVector2)screenSize;

-(void)update;
-(void)render;
-(void)addFluidAtPosX:(float)posX posY:(float)posY;
-(void)removeFluidAtPosX:(float)posX posY:(float)posY;
-(void)flingFluidAtPosX:(float)posX posY:(float)posY withVelX:(float)velX velY:(float)velY;
-(FLSTouchOperation)operationForTouch:(float)posX posY:(float)posY;

-(void)dealloc;

@end
