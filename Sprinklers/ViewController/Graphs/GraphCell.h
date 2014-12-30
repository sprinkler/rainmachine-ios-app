//
//  GraphCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GraphDescriptor;
@class GraphView;

@interface GraphCell : UITableViewCell

@property (nonatomic, strong) GraphDescriptor *graphDescriptor;

@property (nonatomic, weak) IBOutlet UIView *graphContainerView;
@property (nonatomic, weak) IBOutlet UIView *titleAreaContainerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *titleAreaContainerViewHeightLayoutConstraint;
@property (nonatomic, weak) IBOutlet UIView *titleAreaSeparatorView;
@property (nonatomic, weak) IBOutlet UILabel *graphTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *graphUnitsLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *graphUnitsLabelWidthLayoutConstraint;

@property (nonatomic, weak) IBOutlet UIView *iconsBarContainerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *iconsBarContainerViewHeightLayoutConstraint;

@property (nonatomic, weak) IBOutlet UIView *valuesBarContainerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *valuesBarContainerViewHeightLayoutConstraint;
@property (nonatomic, weak) IBOutlet UILabel *valuesUnitsLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *valuesUnitsLabelWidthLayoutConstraint;

@property (nonatomic, weak) IBOutlet GraphView *graphView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *graphViewHeightLayoutConstraint;

@property (nonatomic, weak) IBOutlet UIView *dateBarContainerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *dateBarContainerViewHeightLayoutConstraint;
@property (nonatomic, weak) IBOutlet UILabel *timeIntervalLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *timeIntervalLabelWidthLayoutConstraint;

@property (nonatomic, weak) IBOutlet UILabel *emptyGraphLabel;

@end
