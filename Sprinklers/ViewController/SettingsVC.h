//
//  SettingsVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "Protocols.h"

extern NSString *kSettingsPrograms;
extern NSString *kSettingsWateringHistory;
extern NSString *kSettingsSnooze;
extern NSString *kSettingsRainDelay;
extern NSString *kSettingsRestrictions;
extern NSString *kSettingsWeather;
extern NSString *kSettingsSystemSettings;
extern NSString *kSettingsAbout;
extern NSString *kSettingsSoftwareUpdate;

@interface SettingsVC : BaseViewController <UITableViewDataSource, UITableViewDelegate, TimePickerDelegate, SprinklerResponseProtocol, TimeZoneSelectorDelegate>

- (id)initWithSettings:(NSArray*)settings parentSetting:(NSString*)parentSetting;

- (void)applicationDidEnterInForeground;

@end
