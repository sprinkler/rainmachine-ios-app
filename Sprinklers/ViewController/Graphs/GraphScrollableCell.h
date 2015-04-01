//
//  GraphScrollableCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 16/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GraphDescriptor;
@class GraphView;
@protocol GraphScrollableCellDelegate;

@interface GraphScrollableCell : UITableViewCell <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) GraphDescriptor *graphDescriptor;
@property (nonatomic, weak) id<GraphScrollableCellDelegate> graphScrollableCellDelegate;

@property (nonatomic, weak) IBOutlet UIView *graphContainerView;
@property (nonatomic, weak) IBOutlet UIView *titleAreaContainerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *titleAreaContainerViewHeightLayoutConstraint;
@property (nonatomic, weak) IBOutlet UIView *titleAreaSeparatorView;
@property (nonatomic, weak) IBOutlet UILabel *graphTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *graphUnitsLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *graphUnitsLabelWidthLayoutConstraint;

@property (nonatomic, weak) IBOutlet UILabel *minValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *midValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxValueLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *minValueLabelBottomSpaceLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *midValueLabelBottomSpaceLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *maxValueLabelBottomSpaceLayoutConstraint;

@property (nonatomic, weak) IBOutlet UICollectionView *graphCollectionView;

@property (nonatomic, weak) IBOutlet GraphView *backgroundGraphView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *backgroundGraphViewTopLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *backgroundGraphViewBottomLayoutConstraint;

@property (nonatomic, weak) IBOutlet UILabel *valuesMetricLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *valuesMetricLabelTopSpaceLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *valuesMetricLabelHeightLayoutConstraint;

@property (nonatomic, weak) IBOutlet UILabel *dateLabelTop;
@property (nonatomic, weak) IBOutlet UILabel *dateLabelBottom;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *dateLabelTopHeightLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *dateLabelBottomHeightLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *dateLabelTopBottomSpaceLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *dateLabelBottomBottomSpaceLayoutConstraint;

- (void)scrollToContentOffset:(CGPoint)contentOffset animated:(BOOL)animate;
- (void)scrollToContentOffsetInLayoutSubviews:(CGPoint)contentOffset;
- (void)scrollToCurrentDateAnimated:(BOOL)animate;
- (void)stopScrolling;

@end

#pragma mark -

@protocol GraphScrollableCellDelegate <NSObject>

@optional

- (void)graphScrollableCell:(GraphScrollableCell*)graphScrollableCell didScrollToContentOffset:(CGPoint)contentOffset;
- (void)graphScrollableCellTapped:(GraphScrollableCell*)graphScrollableCell;

@end
