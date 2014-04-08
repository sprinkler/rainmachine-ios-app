//
//  TimePickerVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 26/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"
#import "BaseLevel2ViewController.h"
#import "BaseVC.h"

@interface TimePickerVC : BaseLevel2ViewController

@property (assign) int timeFormat;
@property (weak, nonatomic) BaseVC<TimePickerDelegate> *parent;
@property (strong, nonatomic) NSDate *time;
@property (weak, nonatomic) IBOutlet UIPickerView *datePicker;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* leftConstraint;

- (int)hour24Format;
- (int)minutes;
- (void)refreshUIWithHour:(int)h minutes:(int)m;
- (void) refreshTimeFormatConstraint;

@end
