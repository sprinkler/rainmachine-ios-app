//
//  WindSensitivityVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 23/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class SettingsVC;
@class ColoredBackgroundButton;

@interface WindSensitivityVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate, CellButtonDelegate, SprinklerResponseProtocol>

@property (nonatomic, weak) SettingsVC *parent;

@property (nonatomic, strong) IBOutlet UIView *windSensitivityHeaderView;
@property (nonatomic, weak) IBOutlet ColoredBackgroundButton *defaultsButton;
@property (nonatomic, weak) IBOutlet ColoredBackgroundButton *saveButton;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

- (IBAction)onDefaults:(id)sender;
- (IBAction)onSave:(id)sender;

@end
