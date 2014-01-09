//
//  ZonePropertiesVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 09/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Zone.h"
#import "Protocols.h"

@interface ZonePropertiesVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SprinklerResponseProtocol>

@property (nonatomic, strong) Zone *zone;
@property (nonatomic) BOOL showMasterValve;

@end
