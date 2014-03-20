//
//  DailyProgramVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 23/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"
#import "CCTBackButtonActionHelper.h"

@class Program;
@class ProgramsVC;
@class SetDelayVC;
@class WeekdaysVC;
@class TimePickerVC;

@interface ProgramVC : BaseLevel2ViewController <SprinklerResponseProtocol, CellButtonDelegate, CCTBackButtonActionHelperProtocol, TimePickerDelegate, SetDelayVCDelegate>

@property (copy, nonatomic) Program *program;
@property (weak, nonatomic) ProgramsVC *parent;
@property (assign) int programIndex;

- (void)setDelayVCOver:(SetDelayVC*)setDelayVC;
- (void)weekdaysVCWillDissapear:(WeekdaysVC*)weekdaysVC;
- (void)timePickerVCWillDissapear:(TimePickerVC*)timePickerVC;

@end
