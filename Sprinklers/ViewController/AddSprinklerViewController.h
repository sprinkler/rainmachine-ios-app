//
//  SPAddSprinklerViewController.h
//  Sprinklers
//
//  Created by Fabian Matyas on 03/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Sprinkler;

@interface AddSprinklerViewController : UITableViewController

@property (strong, nonatomic) Sprinkler *sprinkler;

- (IBAction)onSave:(id)sender;

@end
