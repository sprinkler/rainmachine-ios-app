//
//  TimePickerMinutesVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 16/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"
#import "BaseLevel2ViewController.h"
#import "BaseNetworkHandlingVC.h"

@interface TimePickerMinutesVC : BaseLevel2ViewController

@property (assign, nonatomic) int minutes;
@property (assign, nonatomic) int seconds;
@property (assign, nonatomic) int maxMinutes;
@property (strong, nonatomic) id userInfo;
@property (weak, nonatomic) BaseNetworkHandlingVC<TimePickerMinutesDelegate> *parent;

@property (weak, nonatomic) IBOutlet UIPickerView *datePicker;

@end
