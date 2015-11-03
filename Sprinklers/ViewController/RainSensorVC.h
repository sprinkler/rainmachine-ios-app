//
//  RainSensorVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 23/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@interface RainSensorVC : BaseLevel2ViewController <SprinklerResponseProtocol>

@property (nonatomic, weak) IBOutlet UIScrollView *rainSensorScrollView;
@property (nonatomic, strong) IBOutlet UIView *rainSensorContentView;
@property (nonatomic, weak) IBOutlet UISwitch *rainSensorSwitch;
@property (nonatomic, weak) IBOutlet UILabel *rainSensorDescriptionLabel;
@property (nonatomic, weak) IBOutlet UIImageView *rainSensorImageView;

- (IBAction)onSwitchRainSensor:(id)sender;

@end
