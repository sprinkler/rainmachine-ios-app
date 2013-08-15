//
//  AddSprinklerViewController_iPhone.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/17/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Sprinkler.h"

@interface AddSprinklerViewController_iPhone : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) Sprinkler *sprinkler;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)save:(id)sender;

@end
