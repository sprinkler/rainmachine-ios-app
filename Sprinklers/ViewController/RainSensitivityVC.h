//
//  RainSensitivityVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class SettingsVC;
@class ColoredBackgroundButton;

@interface RainSensitivityVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate, SprinklerResponseProtocol>

@property (nonatomic, weak) SettingsVC *parent;

@property (nonatomic, strong) IBOutlet UIView *rainSensitivityHeaderView;
@property (nonatomic, weak) IBOutlet ColoredBackgroundButton *defaultsButton;
@property (nonatomic, weak) IBOutlet ColoredBackgroundButton *saveButton;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

- (IBAction)onDefaults:(id)sender;
- (IBAction)onSave:(id)sender;

@end
