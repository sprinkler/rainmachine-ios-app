//
//  ProvisionWiFiVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 01/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProvisionAvailableWiFisVC.h"
#import "Protocols.h"
#import "DiscoveredSprinklers.h"
#import "BaseNetworkHandlingVC.h"

@interface ProvisionWiFiVC : BaseNetworkHandlingVC<UITextFieldDelegate, SprinklerResponseProtocol, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSString *securityOption;
@property (nonatomic, weak) ProvisionAvailableWiFisVC *delegate;
@property (nonatomic, assign) BOOL showSSID;
@property (nonatomic, strong) NSString *SSID;
@property (strong, nonatomic) DiscoveredSprinklers *sprinkler;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign) BOOL loginAutomatically;

@end
