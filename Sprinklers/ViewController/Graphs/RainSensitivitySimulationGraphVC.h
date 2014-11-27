//
//  RainSensitivitySimulationGraphVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"
#import "BaseLevel2ViewController.h"

@class RainSensitivityVC;

@interface RainSensitivitySimulationGraphVC : BaseLevel2ViewController <SprinklerResponseProtocol>

@property (nonatomic, weak) RainSensitivityVC *parent;
@property (nonatomic, weak) IBOutlet UIScrollView *graphScrollView;

@end

