//
//  ZoneAdvancedTableVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 14/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Zone;
@class ZoneAdvancedVC;
@class ZoneProperties4;

@interface ZoneAdvancedTableVC : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong) Zone *zone;
@property (nonatomic, strong) ZoneProperties4 *zoneProperties;
@property (nonatomic, weak) ZoneAdvancedVC *parent;

- (void)reloadData;
- (void)endEditing;

@end
