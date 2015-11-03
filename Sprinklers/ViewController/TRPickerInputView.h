//
//  TRPickerInputView.h
//
//  Created by Istvan Sipos on 16/10/14.
//

#import <UIKit/UIKit.h>

@class TRPickerInputView;

#pragma mark -

@protocol TRPickerInputViewDataSource <NSObject>

@required

- (NSInteger)numberOfRowsInPickerView:(TRPickerInputView*)pickerInputView;

@end

#pragma mark -

@protocol TRPickerInputViewDelegate <NSObject>

@optional

- (NSString*)pickerView:(TRPickerInputView*)pickerInputView titleForRow:(NSInteger)row;
- (void)pickerView:(TRPickerInputView*)pickerInputView didSelectRow:(NSInteger)row;
- (void)pickerViewDidCancel:(TRPickerInputView*)pickerInputView;

@end

#pragma mark -

@interface TRPickerInputView : UIView <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *saveBarButtonItem;
@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;

@property (nonatomic, weak) id<TRPickerInputViewDataSource> dataSource;
@property (nonatomic, weak) id<TRPickerInputViewDelegate> delegate;

+ (TRPickerInputView*)newPickerInputView;

- (void)selectRow:(NSInteger)row animated:(BOOL)animated;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end
