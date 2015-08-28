//
//  FLSFeelSettingsViewController.m
//  FluidSim
//
//  Created by Avilad on 12/30/14.
//  Copyright (c) 2014 Avilad. All rights reserved.
//

#import "FLSFeelSettingsViewController.h"
#import "FLSGlobalSettings.h"

@interface FLSFeelSettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *feel_viscosityPercentLabel;
@property (weak, nonatomic) IBOutlet UILabel *feel_gravityPercentLabel;

@property (weak, nonatomic) IBOutlet UISlider *feel_viscositySlider;
@property (weak, nonatomic) IBOutlet UISlider *feel_gravitySlider;

@end

@implementation FLSFeelSettingsViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.feel_viscosityPercentLabel setText:[NSString stringWithFormat:@"%i%%", (int)(feel_viscosity * 100.0f)]];
    [self.feel_viscositySlider setValue:feel_viscosity];
    
    [self.feel_gravityPercentLabel setText:[NSString stringWithFormat:@"%i%%", (int)(feel_gravity * 100.0f)]];
    [self.feel_gravitySlider setValue:feel_gravity];
}
- (IBAction)feel_viscositySliderChanged
{
    float sliderValue = [self.feel_viscositySlider value];
    [self.feel_viscosityPercentLabel setText:[NSString stringWithFormat:@"%i%%", (int)(sliderValue * 100.0f)]];
    feel_viscosity = sliderValue;
}
- (IBAction)feel_gravitySliderChanged
{
    float sliderValue = [self.feel_gravitySlider value];
    [self.feel_gravityPercentLabel setText:[NSString stringWithFormat:@"%i%%", (int)(sliderValue * 100.0f)]];
    feel_gravity = sliderValue;
}

@end