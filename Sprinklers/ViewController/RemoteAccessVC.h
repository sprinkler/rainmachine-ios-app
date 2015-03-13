//
//  RemoteAccessVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 13/03/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@interface RemoteAccessVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, SprinklerResponseProtocol>

@property (nonatomic, strong) BaseNetworkHandlingVC<SprinklerResponseProtocol> *parent;

@end
