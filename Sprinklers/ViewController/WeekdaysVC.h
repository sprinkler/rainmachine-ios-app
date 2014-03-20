//
//  WeekdaysVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 24/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"

@class ProgramVC;

@interface WeekdaysVC : BaseLevel2ViewController

@property (nonatomic, strong) NSMutableArray *selectedWeekdays;

@property (weak, nonatomic) ProgramVC *parent;

@end
