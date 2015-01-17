//
//  GraphScrollableCell.m
//  Sprinklers
//
//  Created by Istvan Sipos on 16/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "GraphScrollableCell.h"
#import "GraphCell.h"
#import "GraphDescriptor.h"
#import "GraphTimeInterval.h"
#import "GraphTimeIntervalPart.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphTitleAreaDescriptor.h"

#pragma mark -

@interface GraphScrollableCell ()

- (void)setup;
- (void)setupVisualAppearanceWithDescriptor:(GraphVisualAppearanceDescriptor*)descriptor;
- (void)setupTitleAreaWithDescriptor:(GraphTitleAreaDescriptor*)descriptor;

@end

#pragma mark -

@implementation GraphScrollableCell

#pragma mark - Initializing

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;
    
    [self addObserver:self forKeyPath:@"graphDescriptor" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self addObserver:self forKeyPath:@"graphDescriptor.dataSource" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self addObserver:self forKeyPath:@"graphDescriptor.dataSource.values" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self addObserver:self forKeyPath:@"graphDescriptor.dataSource.topValues" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self addObserver:self forKeyPath:@"graphDescriptor.dataSource.iconImageIndexes" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"graphDescriptor"];
    [self removeObserver:self forKeyPath:@"graphDescriptor.dataSource"];
    [self removeObserver:self forKeyPath:@"graphDescriptor.dataSource.values"];
    [self removeObserver:self forKeyPath:@"graphDescriptor.dataSource.topValues"];
    [self removeObserver:self forKeyPath:@"graphDescriptor.dataSource.iconImageIndexes"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    [self setup];
}

- (void)awakeFromNib {
    [self.graphCollectionView registerNib:[UINib nibWithNibName:@"GraphCell" bundle:nil] forCellWithReuseIdentifier:@"GraphCell"];
    [self.graphCollectionView reloadData];
}

- (void)setup {
    [self setupVisualAppearanceWithDescriptor:self.graphDescriptor.visualAppearanceDescriptor];
    [self setupTitleAreaWithDescriptor:self.graphDescriptor.titleAreaDescriptor];
    
    [self.graphCollectionView reloadData];
}

#pragma mark - Visual appearance

- (void)setupVisualAppearanceWithDescriptor:(GraphVisualAppearanceDescriptor*)descriptor {
    self.graphContainerView.backgroundColor = descriptor.backgroundColor;
    if (descriptor.cornerRadius > 0.0) self.graphContainerView.layer.cornerRadius = descriptor.cornerRadius;
    else self.graphContainerView.layer.cornerRadius = 0.0;
}

- (void)setupTitleAreaWithDescriptor:(GraphTitleAreaDescriptor*)descriptor {
    self.titleAreaContainerViewHeightLayoutConstraint.constant = descriptor.titleAreaHeight;
    self.titleAreaSeparatorView.backgroundColor = descriptor.titleAreaSeparatorColor;
    self.graphTitleLabel.text = descriptor.title;
    self.graphTitleLabel.textColor = descriptor.titleColor;
    self.graphTitleLabel.font = descriptor.titleFont;
    self.graphUnitsLabel.text = descriptor.units;
    self.graphUnitsLabel.textColor = descriptor.unitsColor;
    self.graphUnitsLabel.font = descriptor.unitsFont;
    self.graphUnitsLabelWidthLayoutConstraint.constant = self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
}

#pragma mark - Utils

- (void)scrollToContentOffset:(CGPoint)contentOffset animated:(BOOL)animate {
    id graphCollectionViewDelegate = self.graphCollectionView.delegate;
    self.graphCollectionView.delegate = nil;
    [self.graphCollectionView setContentOffset:contentOffset animated:animate];
    self.graphCollectionView.delegate = graphCollectionViewDelegate;
}

- (void)stopScrolling {
    [self.graphCollectionView setContentOffset:self.graphCollectionView.contentOffset animated:NO];
}

#pragma mark - Graph collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.graphDescriptor.graphTimeInterval.graphTimeIntervalParts.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    GraphTimeIntervalPart *graphTimeIntervalPart = nil;
    if (indexPath.item < self.graphDescriptor.graphTimeInterval.graphTimeIntervalParts.count) graphTimeIntervalPart = self.graphDescriptor.graphTimeInterval.graphTimeIntervalParts[indexPath.item];
    
    GraphCell *graphCell =[collectionView dequeueReusableCellWithReuseIdentifier:@"GraphCell" forIndexPath:indexPath];
    graphCell.graphTimeIntervalPart = graphTimeIntervalPart;
    graphCell.graphDescriptor = self.graphDescriptor;
    return graphCell;
}

#pragma mark - Graph collection view delegate flow layout

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath*)indexPath {
    return CGSizeMake(self.graphCollectionView.bounds.size.width, self.graphDescriptor.totalGraphHeight - self.graphDescriptor.titleAreaDescriptor.titleAreaHeight - 6.0);
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeZero;
}

#pragma mark Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    if (self.graphScrollableCellDelegate && [self.graphScrollableCellDelegate respondsToSelector:@selector(graphScrollableCell:didScrollToContentOffset:)]) {
        [self.graphScrollableCellDelegate graphScrollableCell:self didScrollToContentOffset:self.graphCollectionView.contentOffset];
    }
}

@end
