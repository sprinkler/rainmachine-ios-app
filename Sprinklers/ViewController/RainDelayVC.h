//
//  RainDelayVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 08/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class SettingsVC;

@interface RainDelayVC : BaseLevel2ViewController <SprinklerResponseProtocol>

@property (weak, nonatomic) SettingsVC *parent;


@end
