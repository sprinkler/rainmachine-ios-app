//
//  SprinklerStaticListViewController.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/30/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SprinklerStaticListViewController : UIViewController {
    NSMutableArray *savedSprinklers;
    UIBarButtonItem *editButton;
}

@property (nonatomic) BOOL shouldDisplayAdd;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
