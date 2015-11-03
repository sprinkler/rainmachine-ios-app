//
//  ZoneAdvancedPropertyCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 30/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZoneAdvancedPropertyCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *propertyNameLabel;
@property (nonatomic, weak) IBOutlet UITextField *propertyValueTextField;

@end
