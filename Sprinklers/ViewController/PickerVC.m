//
//  PickerVC.m
//  Sprinklers
//
//  Created by Adrian Manolache on 18/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "PickerVC.h"

@interface PickerVC ()

@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;
@property (nonatomic, weak) IBOutlet UILabel *selectionTitleLabel;

@end

#pragma mark -

@implementation PickerVC

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.pickerView reloadAllComponents];
    self.selectionTitleLabel.text = self.selectedItemTitle;
    if (self.selectedItem) {
        NSInteger selectedRow = [self.itemsArray indexOfObject:self.selectedItem];
        if (selectedRow != NSNotFound) [self.pickerView selectRow:selectedRow inComponent:0 animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.parent pickerVCWillDissapear:self];
}

#pragma Picker view data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView*)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.itemsArray.count;
}

#pragma mark - Picker view delegate

- (NSString*)pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.itemsDisplayStringArray[row];
}

- (void)pickerView:(UIPickerView*)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedItem = self.itemsArray[row];
}

@end
