//
//  CloudAccountsVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 19/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CloudAccountsVC : UITableViewController

@property (strong, nonatomic) NSDictionary *cloudResponse;
@property (strong, nonatomic) NSMutableArray *cloudEmails;
@property (strong, nonatomic) NSDictionary *cloudSprinklers;
@property (assign, nonatomic) BOOL currentSprinklerDeleted;

@end
