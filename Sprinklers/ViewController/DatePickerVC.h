//
//  DatePickerVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 26/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DailyProgramVC;

@interface DatePickerVC : UIViewController

@property (assign) int timeFormat;
@property (weak, nonatomic) DailyProgramVC *parent;
@property (strong, nonatomic) NSDate *time;

- (int)hour24Format;
- (int)minutes;

@end
