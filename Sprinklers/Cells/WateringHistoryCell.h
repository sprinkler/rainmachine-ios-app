//
//  WateringHistoryCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 24/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WateringHistoryCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *firstColumnLabel;
@property (nonatomic, weak) IBOutlet UILabel *secondColumnLabel;

@end
