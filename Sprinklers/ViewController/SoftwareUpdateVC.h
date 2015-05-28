//
//  SoftwareUpdateVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 01/05/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class ColoredBackgroundButton;

@interface SoftwareUpdateVC : BaseLevel2ViewController <SprinklerResponseProtocol, UpdateManagerDelegate>

@property (nonatomic, weak) IBOutlet UIView *updateContainerView;
@property (nonatomic, weak) IBOutlet ColoredBackgroundButton *updateButton;
@property (nonatomic, weak) IBOutlet UILabel *updateVersionLabel;
@property (nonatomic, weak) IBOutlet UILabel *currentVersionLabel;

- (IBAction)updateAction:(id)sender;

@end
