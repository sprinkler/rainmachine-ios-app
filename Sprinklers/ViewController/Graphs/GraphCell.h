//
//  GraphCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GraphDescriptor;
@class GraphTimeIntervalPart;
@class GraphView;

@interface GraphCell : UICollectionViewCell

@property (nonatomic, strong) GraphDescriptor *graphDescriptor;
@property (nonatomic, strong) GraphTimeIntervalPart *graphTimeIntervalPart;

@property (nonatomic, weak) IBOutlet UIView *graphContainerView;

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

@end
