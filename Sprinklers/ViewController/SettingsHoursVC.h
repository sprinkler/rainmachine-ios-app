//
//  SettingsHoursVC.h
//  Sprinklers
//
//  Created by Adrian Manolache on 18/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsHoursVC : UIViewController
    
@property(nonatomic, retain) IBOutlet UITableView* tableView;

@property(nonatomic, retain) NSMutableArray* restrictions;

@end
