//
//  FLSColorPickerViewController.m
//  FluidSim
//
//  Created by SlEePlEs5 on 12/29/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import "FLSColorPickerViewController.h"
#import "FLSGlobalSettings.h"
#import <NKOColorPickerView.h>

@interface FLSColorPickerViewController ()

@property (nonatomic, weak) IBOutlet NKOColorPickerView *pickerView;

@end


@implementation FLSColorPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.pickerView setTintColor:[UIColor colorWithRed:(170.0f/255.0f)
                                                  green:(190.0f/255.0f)
                                                   blue:(210.0f/255.0f)
                                                  alpha:(1.0f)]];
    
    [self.pickerView setColor:[UIColor colorWithRed:look_baseColor.x green:look_baseColor.y blue:look_baseColor.z alpha:1.0f]];
    
    [self.pickerView setDidChangeColorBlock:^(UIColor *color)
    {
        CGFloat red;
        CGFloat green;
        CGFloat blue;
        [self.pickerView.color getRed:&red green:&green blue:&blue alpha:NULL];
        look_baseColor = GLKVector3Make(red, green, blue);
    }];
}

@end
