//
//  WeekdaysVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 24/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DailyProgramVC;

@interface WeekdaysVC : UIViewController

@property (nonatomic, strong) NSMutableArray *selectedWeekdays;

@property (weak, nonatomic) DailyProgramVC *parent;

@end
