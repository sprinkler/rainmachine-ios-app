//
//  SettingsDatePickerVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 03/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "DatePickerVC.h"
#import "SettingsDate.h"
#import "MBProgressHUD.h"
#import "ServerProxy.h"
#import "ServerResponse.h"
#import "SettingsVC.h"
#import "Utils.h"
#import "+UIDevice.h"
#import "+NSDate.h"

@interface DatePickerVC ()

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalConstraint;

@end

@implementation DatePickerVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Date";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.date) [self.datePicker setDate:self.date animated:NO];
    
    if (![[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.view.backgroundColor = [UIColor blackColor];
        
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.datePicker
                                                                      attribute:NSLayoutAttributeTop
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1.0
                                                                       constant:0];
        
        [self.view removeConstraint:self.verticalConstraint];
        [self.view addConstraint:constraint];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.date = self.datePicker.date;
    [self.parent datePickerVCWillDissapear:self];
}

@end
