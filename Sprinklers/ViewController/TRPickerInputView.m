//
//  TRPickerInputView.m
//
//  Created by Istvan Sipos on 16/10/14.
//

#import "TRPickerInputView.h"

@implementation TRPickerInputView

+ (TRPickerInputView*)newPickerInputView {
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"PickerInputView" owner:nil options:nil];
    return views[0];
}

- (void)awakeFromNib {
    self.cancelBarButtonItem.title = @"Cancel";
    self.saveBarButtonItem.title = @"OK";
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    self.pickerView.backgroundColor = [UIColor clearColor];
    
    self.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    
    self.layer.shadowOpacity = 0.5;
    self.layer.shadowRadius = 5.0f;
    self.layer.shadowColor = [UIColor grayColor].CGColor;

}

- (void)selectRow:(NSInteger)row animated:(BOOL)animated {
    [self.pickerView selectRow:row inComponent:0 animated:animated];
}

#pragma mark - Picker view data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView*)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.dataSource numberOfRowsInPickerView:self];
}

#pragma mark - Picker view delegate

- (NSString*)pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if ([self.delegate respondsToSelector:@selector(pickerView:titleForRow:)]) {
        return [self.delegate pickerView:self titleForRow:row];
    }
    return nil;
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender {
    [self.delegate pickerViewDidCancel:self];
}

- (IBAction)save:(id)sender {
    [self.delegate pickerView:self didSelectRow:[self.pickerView selectedRowInComponent:0]];
}

@end
