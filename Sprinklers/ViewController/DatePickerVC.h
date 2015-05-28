//
//  DatePickerVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 03/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"
#import "BaseLevel2ViewController.h"

@class SettingsVC;

@interface DatePickerVC : BaseLevel2ViewController

@property (weak, nonatomic) BaseNetworkHandlingVC<DatePickerDelegate> *parent;
@property (strong, nonatomic) NSDate *date;

@end
