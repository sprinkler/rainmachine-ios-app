//
//  WaterNowLevel1VC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class WaterNowZone;
@class ServerProxy;
@class WaterNowVC;

@interface WaterNowLevel1VC : BaseLevel2ViewController<SprinklerResponseProtocol, WaterNowCounterHelperDelegate>

@property (strong, nonatomic) WaterNowVC *parent;
@property (strong, nonatomic) WaterNowZone *wateringZone;

- (IBAction)onUpButton:(id)sender;
- (IBAction)onDownButton:(id)sender;
- (IBAction)onStartButton:(id)sender;

@end
