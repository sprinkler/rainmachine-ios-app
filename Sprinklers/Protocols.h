//
//  Protocols.h
//  AFNetworking iOS Example
//
//  Created by Fabian Matyas on 02/12/13.
//  Copyright (c) 2013 Gowalla. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WaterNowZone.h"
#import "AFHTTPRequestOperation.h"

@protocol SprinklerResponseProtocol <NSObject>

- (void)loggedOut;
- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo;
- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo;

@optional
- (void)loginSucceededAndRemembered:(BOOL)remembered loginResponse:(id)loginResponse unit:(NSString*)unit;

@end

@protocol CellButtonDelegate <NSObject>

@optional
- (void)onCellButton;
- (void)onCellSwitch:(id)object;
- (void)onCellSliderValueChanged:(id)object;
- (void)cellTextFieldChanged:(NSString*)text;
- (void)onCell:(UITableViewCell*)cell checkmarkState:(BOOL)sel;

@end

@protocol TimePickerDelegate <NSObject>

- (void)timePickerVCWillDissapear:(id)timePicker;

@end

@protocol DatePickerDelegate <NSObject>

- (void)datePickerVCWillDissapear:(id)datePicker;

@end

@class PickerVC;

@protocol PickerVCDelegate <NSObject>

- (void)pickerVCWillDissapear:(PickerVC*)pickerVC;

@end

@class WeekdaysVC;

@protocol WeekdaysVCDelegate <NSObject>

- (void)weekdaysVCWillDissapear:(WeekdaysVC*)weekdaysVC;

@end

@class MonthsVC;

@protocol MonthsVCDelegate <NSObject>

- (void)monthsVCWillDissapear:(MonthsVC*)monthsVC;

@end

@protocol SetDelayVCDelegate <NSObject>

- (void)setDelayVCOver:(id)setDelayVC;

@end

@protocol CounterHelperDelegate<NSObject>

- (void)showCounterLabel;
- (BOOL)isCounteringActive;
- (int)counterValue;
- (void)setCounterValue:(int)value;

@end

@protocol RainDelayPollerDelegate <NSObject>

- (void)handleSprinklerNetworkError:(NSError*)error operation:(AFHTTPRequestOperation *)operation showErrorMessage:(BOOL)showErrorMessage;
- (void)handleSprinklerGeneralError:(NSString *)errorMessage showErrorMessage:(BOOL)showErrorMessage;
- (void)hideHUD;
- (void)refreshStatus;
- (void)rainDelayResponseReceived;
- (void)hideRainDelayActivityIndicator:(BOOL)hide;
- (void)loggedOut;

@end

@protocol UpdateManagerDelegate <NSObject>

- (void)sprinklerVersionReceivedMajor:(int)major minor:(int)minor subMinor:(int)subMinor;
- (void)updateNowAvailable:(BOOL)available withVersion:(NSString *)the_new_version;

@end

@protocol TimeZoneSelectorDelegate <NSObject>

- (NSString*)timeZoneName;
- (void)timeZoneSelected:(NSString*)timeZoneName;


@end