//
//  ProgramsVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 05/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@interface ProgramsVC : BaseLevel2ViewController <UITableViewDelegate, UITableViewDataSource, SprinklerResponseProtocol>

@end
