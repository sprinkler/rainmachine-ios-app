//
//  Protocols.h
//  AFNetworking iOS Example
//
//  Created by Fabian Matyas on 02/12/13.
//  Copyright (c) 2013 Gowalla. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SprinklerResponseProtocol <NSObject>

- (void)loggedOut;
- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy userInfo:(id)userInfo;
- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo;

@optional
- (void)loginSucceededAndRemembered:(BOOL)remembered;

@end

@protocol CellButtonDelegate <NSObject>
- (void)onCellButton;
- (void)onCellSwitch:(id)object;
- (void)cellTextFieldChanged:(NSString*)text;
- (void)onCell:(UITableViewCell*)cell checkmarkState:(BOOL)sel;

@end

@protocol TimePickerDelegate <NSObject>

- (void)timePickerVCWillDissapear:(id)timePicker;
- (void)handleGeneralSprinklerError:(NSString *)errorMessage showErrorMessage:(BOOL)showErrorMessage;

@end