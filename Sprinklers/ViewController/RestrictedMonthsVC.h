//
//  RestrictedMonthsVC.h
//  Sprinklers
//
//  Created by Adrian Manolache on 14/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RestrictedMonthsVC : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, retain) IBOutlet UITableView* tableView;
    
@property(nonatomic, retain) NSString* restrictedMonths;

@end
