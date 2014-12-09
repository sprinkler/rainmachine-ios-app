//
//  DashboardVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class GraphTimeInterval;

@interface DashboardVC : BaseLevel2ViewController

@property (nonatomic, strong) GraphTimeInterval *graphTimeInterval;

@end
