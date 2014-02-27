//
//  SetDelayVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 25/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "SetDelayVC.h"
#import "DailyProgramVC.h"

@interface SetDelayVC ()

@property (weak, nonatomic) IBOutlet UILabel *title1;
@property (weak, nonatomic) IBOutlet UILabel *title2;
@property (weak, nonatomic) IBOutlet UIPickerView *picker1;
@property (weak, nonatomic) IBOutlet UIPickerView *picker2;
@property (weak, nonatomic) IBOutlet UIView *helperView2;

@end

@implementation SetDelayVC

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
    
    if (_maxValuePicker1 == 0) {
        _maxValuePicker1 = 500;
    }
    if (_maxValuePicker2 == 0) {
        _maxValuePicker2 = 500;
    }
    
	// Do any additional setup after loading the view.
    _picker1.hidden = (_titlePicker1 == nil);
    _picker2.hidden = (_titlePicker2 == nil);
    
    if (_picker2.hidden) {
        [_helperView2 removeFromSuperview];
        [_picker2 removeFromSuperview];
    }
    
    _title1.hidden = _picker1.hidden;
    _title2.hidden = _picker2.hidden;
    
    [_picker1 selectRow:(_valuePicker1 - _minValuePicker1) inComponent:0 animated:NO];
    [_picker2 selectRow:(_valuePicker2 - _minValuePicker2) inComponent:0 animated:NO];
    
    _title1.text = _titlePicker1;
    _title2.text = _titlePicker2;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated{
    self.valuePicker1 = _minValuePicker1 + [self.picker1 selectedRowInComponent:0];
    self.valuePicker2 = _minValuePicker2 + [self.picker2 selectedRowInComponent:0];
    
    [self.parent setDelayVCOver:self];
}

#pragma mark - Picker delegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (pickerView == _picker1) {
        return [NSString stringWithFormat:@"%d", _minValuePicker1 + row];
    }
    if (pickerView == _picker2) {
        return [NSString stringWithFormat:@"%d", _minValuePicker2 + row];
    }
    
    return [NSString stringWithFormat:@"%d", row];
}

#pragma mark - Picker data source

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component
{
    if (pickerView == _picker1) {
        return _maxValuePicker1 - _minValuePicker1+ 1;
    }
    if (pickerView == _picker2) {
        return _maxValuePicker2 - _minValuePicker2 + 1;
    }
    
    return 501;
}

@end
