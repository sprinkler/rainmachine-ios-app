//
//  TimePickerVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 26/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "TimePickerVC.h"
#import "+UIDevice.h"

@interface TimePickerVC ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalConstraint;
@property (weak, nonatomic) IBOutlet UILabel* separatorLabel;

@end

@implementation TimePickerVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    if (self.time) {
        NSCalendar* cal = [NSCalendar currentCalendar];
        NSDateComponents* dateComp = [cal components:(
                                                      NSHourCalendarUnit |
                                                      NSMinuteCalendarUnit
                                                      )
                                            fromDate:self.time];
     
        [self refreshUIWithHour:(int)dateComp.hour minutes:(int)dateComp.minute];
    }
    
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
    
    self.title = @"Start time";
}

- (void)refreshUIWithHour:(int)h minutes:(int)m
{
    [self.datePicker selectRow:((_timeFormat == 0) ? h : h % 12) inComponent:0 animated:NO];
    [self.datePicker selectRow:m inComponent:1 animated:NO];
    if (self.timeFormat == 1) {
        [self.datePicker selectRow:(h / 12) inComponent:2 animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.parent timePickerVCWillDissapear:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Picker delegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
        // Hours
        
        if (row < 10)
            return [NSString stringWithFormat:@"0%d", (int)row];
        
        return [NSString stringWithFormat:@"%d", (int)row];
    }
    else if (component == 1) {
        if (row < 10)
            return [NSString stringWithFormat:@"0%d", (int)row];
        
        return [NSString stringWithFormat:@"%d", (int)row];
    }
    else if (component == 2) {
        return (row == 0) ? @"AM" : @"PM";
    }
    
    return @"";
}

#pragma mark - Picker data source

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return ((_timeFormat == 0) ? 2 : 3);
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component
{
    if (component == 0) {
        return (_timeFormat == 0) ? 24 : 12;
    }
    else if (component == 1) {
        return 60;
    }
    else if (component == 2) {
        return 2;
    }
    
    return 0;
}

# pragma - Getters

- (int)hour24Format
{
    return (_timeFormat == 0) ? (int)[_datePicker selectedRowInComponent:0] : ((int)[_datePicker selectedRowInComponent:2] * 12 + (int)[_datePicker selectedRowInComponent:0]);
}

- (int)minutes
{
    return (int)[_datePicker selectedRowInComponent:1];
}

@end
