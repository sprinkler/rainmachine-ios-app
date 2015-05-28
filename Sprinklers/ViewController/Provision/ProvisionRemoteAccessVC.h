//
//  ProvisionRemoteAccessVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 13/03/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseWizardVC.h"
#import "Protocols.h"

@class DiscoveredSprinklers;
@class Sprinkler;
@class ColoredBackgroundButton;

@interface ProvisionRemoteAccessVC : BaseWizardVC <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UITextFieldDelegate, SprinklerResponseProtocol>

@property (strong, nonatomic) DiscoveredSprinklers *sprinkler;
@property (strong, nonatomic) Sprinkler *dbSprinkler;

@property (weak, nonatomic) IBOutlet UITextField *emailAddressTextField;
@property (weak, nonatomic) IBOutlet ColoredBackgroundButton *saveButton;

- (IBAction)onSave:(id)sender;

@end
