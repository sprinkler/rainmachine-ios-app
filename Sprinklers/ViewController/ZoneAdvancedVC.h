//
//  ZoneAdvancedVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 30/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class Zone;
@class ZoneVC;

@interface ZoneAdvancedVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate, SprinklerResponseProtocol>

@property (nonatomic, strong) Zone *zone;
@property (nonatomic, weak) ZoneVC *parent;

@end
