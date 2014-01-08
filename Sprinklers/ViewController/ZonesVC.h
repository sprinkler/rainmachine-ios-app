//
//  ZonesVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 08/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@interface ZonesVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate, SprinklerResponseProtocol>

@end
