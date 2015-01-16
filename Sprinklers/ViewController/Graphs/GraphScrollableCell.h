//
//  GraphScrollableCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 16/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GraphDescriptor;
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

@property (nonatomic, weak) IBOutlet UICollectionView *graphCollectionView;

- (void)scrollToContentOffset:(CGPoint)contentOffset animated:(BOOL)animate;

@end

#pragma mark -

@protocol GraphScrollableCellDelegate <NSObject>

@optional

- (void)graphScrollableCell:(GraphScrollableCell*)graphScrollableCell didScrollToContentOffset:(CGPoint)contentOffset;

@end
