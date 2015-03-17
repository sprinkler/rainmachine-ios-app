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

@interface ProvisionRemoteAccessVC : BaseWizardVC <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, SprinklerResponseProtocol>

@property (strong, nonatomic) DiscoveredSprinklers *sprinkler;
@property (strong, nonatomic) Sprinkler *dbSprinkler;

@end
