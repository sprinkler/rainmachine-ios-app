//
//  StatsShowGraphsCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphTimeInterval.h"

@interface StatsShowGraphsCell : UITableViewCell

@property (nonatomic, strong) GraphTimeInterval *graphsTimeInterval;
@property (nonatomic, strong) IBOutlet UILabel *graphsTimeIntervalLabel;

@end
