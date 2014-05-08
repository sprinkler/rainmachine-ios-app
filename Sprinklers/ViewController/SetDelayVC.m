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

@property (weak, nonatomic) IBOutlet UILabel *title1;
@property (weak, nonatomic) IBOutlet UILabel *title2;
@property (weak, nonatomic) IBOutlet UILabel *title2Right;
@property (weak, nonatomic) IBOutlet UIPickerView *picker1;
@property (weak, nonatomic) IBOutlet UIPickerView *picker2;
@property (weak, nonatomic) IBOutlet UIView *helperView2;
@property (weak, nonatomic) IBOutlet UIView *helperView1;

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
    
    if ((![[UIDevice currentDevice] iOSGreaterThan:7]) && (_titlePicker2 == nil)) {
        // iOS 6: Make picker snap to top
        [_picker2 removeFromSuperview];
        [_title2 removeFromSuperview];
        [_helperView1 removeFromSuperview];
        [_helperView2 removeFromSuperview];

        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_picker1
                                                                      attribute:NSLayoutAttributeTop
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1.0
                                                                       constant:0];
        [self.view addConstraint:constraint];
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
        [_helperView2 removeFromSuperview];
        [_picker2 removeFromSuperview];
    }
    
    _title1.hidden = _picker1.hidden;
    _title2.hidden = _picker2.hidden;
    
    _valuePicker1 = MAX(_valuePicker1, _minValuePicker1);
    _valuePicker2 = MAX(_valuePicker2, _minValuePicker2);
    
    [_picker1 selectRow:(_valuePicker1 - _minValuePicker1) inComponent:0 animated:NO];
    [_picker2 selectRow:(_valuePicker2 - _minValuePicker2) inComponent:0 animated:NO];
    
    _title1.text = _titlePicker1;
    _title2.text = _titlePicker2;

}

- (void)updateViewConstraints {

    if (_moveLabelsLeftOfPicker == YES )
    {
        if (!_hasLoadedConstraints) {
            // change contraint to have labels on the left
            for (int i=0; i<self.view.constraints.count; i++)
            {
                NSLayoutConstraint* constraint = [self.view.constraints objectAtIndex: i];
                if (constraint.constant == -33.0f)
                    constraint.constant = 145.0f;
            }
        
            _hasLoadedConstraints = TRUE;
        }
    }else
    {
        _title2Right.hidden = YES;
    }
    
    [super updateViewConstraints];
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

- (void)viewWillAppear:(BOOL)animated
{
    float yCompressionValue = ((self.view.frame.size.height / 2.0) / 216) * 1.02;
    _picker1.transform = CGAffineTransformMakeScale(1, yCompressionValue);
    _picker2.transform = CGAffineTransformMakeScale(1, yCompressionValue);
    
//    NSLog(@"");
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
