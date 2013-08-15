//
//  SprinklerStaticListViewController_iPhone.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/30/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SprinklerStaticListViewController_iPhone : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    NSMutableArray *savedSprinklers;
    UIBarButtonItem *editButton;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) BOOL shouldDisplayAdd;

@end
