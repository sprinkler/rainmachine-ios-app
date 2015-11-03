//
//  VegetationTypeVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 04/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"

@class ZoneVC;

@interface VegetationTypeVC : BaseLevel2ViewController

@property (weak, nonatomic) ZoneVC *parent;
@property (assign) int vegetationType;

@end
