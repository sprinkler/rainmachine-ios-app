//
//  DatePickerVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 26/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "DatePickerVC.h"
#import "DailyProgramVC.h"

@interface DatePickerVC ()

@property (weak, nonatomic) IBOutlet UIPickerView *datePicker;

@end

@implementation DatePickerVC

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
    
    NSCalendar* cal = [NSCalendar currentCalendar];
    NSDateComponents* dateComp = [cal components:(
                                                  NSHourCalendarUnit |
                                                  NSMinuteCalendarUnit
                                                  )
                                        fromDate:self.time];
    
    [self.datePicker selectRow:((_timeFormat == 0) ? dateComp.hour : dateComp.hour % 12) inComponent:0 animated:NO];
    [self.datePicker selectRow:dateComp.minute inComponent:1 animated:NO];
    if (self.timeFormat == 1) {
        [self.datePicker selectRow:(dateComp.hour / 12) inComponent:2 animated:NO];
    }
    
    self.title = @"Start time";
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.parent datePickerVCWillDissapear:self];
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
        return [NSString stringWithFormat:@"%d", row];
    }
    else if (component == 1) {
        // Minutes
        return [NSString stringWithFormat:@"%d", row];
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
    return (_timeFormat == 0) ? 2 : 3;
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
    return (_timeFormat == 0) ? [_datePicker selectedRowInComponent:0] : ([_datePicker selectedRowInComponent:2] * 12 + [_datePicker selectedRowInComponent:0]);
}

- (int)minutes
{
    return [_datePicker selectedRowInComponent:1];
}

@end
