//
//  TimePickerMinutesVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 16/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "TimePickerMinutesVC.h"
#import "+UIDevice.h"

#pragma mark -

@interface TimePickerMinutesVC ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalConstraint;
@property (weak, nonatomic) IBOutlet UILabel* separatorLabel;

- (void)refreshUIWithMinutes:(int)minutes seconds:(int)seconds;

@end

#pragma mark -

@implementation TimePickerMinutesVC {
    int _minutes;
    int _seconds;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;
    
    _maxMinutes = 60;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self refreshUIWithMinutes:_minutes seconds:_seconds];
    
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

- (void)refreshUIWithMinutes:(int)minutes seconds:(int)seconds {
    [self.datePicker selectRow:minutes inComponent:0 animated:NO];
    [self.datePicker selectRow:seconds inComponent:1 animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.parent timePickerMinutesVCWillDissapear:self];
}

#pragma mark - Picker delegate

- (NSString*)pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (component == 0) {
        if (row < 10) return [NSString stringWithFormat:@"0%d",(int)row];
        return [NSString stringWithFormat:@"%d",(int)row];
    }
    else if (component == 1) {
        if (row < 10) return [NSString stringWithFormat:@"0%d", (int)row];
        return [NSString stringWithFormat:@"%d", (int)row];
    }
    return @"";
}

#pragma mark - Picker data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component {
    if (component == 0) return self.maxMinutes;
    return 60;
}

#pragma - Properties

- (void)setMinutes:(int)minutes {
    _minutes = minutes;
}

- (void)setSeconds:(int)seconds {
    _seconds = seconds;
}

- (int)minutes {
    return (int)[_datePicker selectedRowInComponent:0];
}

- (int)seconds {
    return (int)[_datePicker selectedRowInComponent:1];
}

@end
