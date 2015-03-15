//
//  SetDelayVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 25/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "SetDelayVC.h"
#import "+UIDevice.h"

@interface SetDelayVC ()

@property (weak, nonatomic) IBOutlet UIPickerView *picker1;
@property (weak, nonatomic) IBOutlet UIPickerView *picker2;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpacePicker2;

@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UILabel *label3;
@property (weak, nonatomic) IBOutlet UILabel *label4;

@property BOOL hasLoadedConstraints;

@end

@implementation SetDelayVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _hasLoadedConstraints = NO;
        _moveLabelsLeftOfPicker = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ((![[UIDevice currentDevice] iOSGreaterThan:7]) && (_titlePicker2 == nil) && [[UIDevice currentDevice] isIpad]) {
        // iOS 6: Make picker snap to top
        [_picker2 removeFromSuperview];
        
        self.view.backgroundColor = [UIColor blackColor];
    }
    
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
        [_picker2 removeFromSuperview];
    
        _label1.hidden = _label3.hidden = _label4.hidden = YES;
        _label2.text = _titlePicker1;
    }else
    {
        _label2.hidden = YES;
        _label1.text = _titlePicker1;
        _label3.text = _titlePicker2;
        _label4.text = @"minutes";
    }
    
    _valuePicker1 = MAX(_valuePicker1, _minValuePicker1);
    _valuePicker2 = MAX(_valuePicker2, _minValuePicker2);
    
    [_picker1 selectRow:(_valuePicker1 - _minValuePicker1) inComponent:0 animated:NO];
    [_picker2 selectRow:(_valuePicker2 - _minValuePicker2) inComponent:0 animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.valuePicker1 = _minValuePicker1 + (int)[self.picker1 selectedRowInComponent:0];
    self.valuePicker2 = _minValuePicker2 + (int)[self.picker2 selectedRowInComponent:0];
    
    [self.parent setDelayVCOver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([[UIDevice currentDevice] isIpad])
        return;
    
    float dyCompressionValue = (((self.view.frame.size.height - self.tabBarController.tabBar.frame.size.height) / 2.0) / 216);
    
    if (dyCompressionValue > 1) {
        dyCompressionValue = 1;
    }

    float yCompressionValue = dyCompressionValue;// * 0.95;
    
    if (yCompressionValue != 1) {
        _picker1.transform = CGAffineTransformMakeScale(1, yCompressionValue);
        _picker2.transform = CGAffineTransformMakeScale(1, yCompressionValue);
    }

    self.topSpacePicker2.constant = _picker1.frame.size.height + 24;
}

#pragma mark - Picker delegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (_moveLabelsLeftOfPicker) {
        if ((![[UIDevice currentDevice] iOSGreaterThan:7])) { // iOS 6: Make picker snap to top
            if (component == 0) {
                return @"";
            }
        }
    }
    
    if (pickerView == _picker1) {
        return [NSString stringWithFormat:@"%d", (int)(_minValuePicker1 + row)];
    }
    if (pickerView == _picker2) {
        return [NSString stringWithFormat:@"%d", (int)(_minValuePicker2 + row)];
    }
    
    return [NSString stringWithFormat:@"%d", (int)row];
}

#pragma mark - Picker data source

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    if (_moveLabelsLeftOfPicker) {
        if ((![[UIDevice currentDevice] iOSGreaterThan:7])) { // iOS 6: Make picker snap to top
            return 2;
        }
    }
    
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component
{
    if (_moveLabelsLeftOfPicker) {
        if ((![[UIDevice currentDevice] iOSGreaterThan:7])) { // iOS 6: Make picker snap to top
            if (component == 0) {
                return 1;
            }
        }
    }
    
    if (pickerView == _picker1) {
        return _maxValuePicker1 - _minValuePicker1+ 1;
    }
    if (pickerView == _picker2) {
        return _maxValuePicker2 - _minValuePicker2 + 1;
    }
    
    return 501;
}

@end
