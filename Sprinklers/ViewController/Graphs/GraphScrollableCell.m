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
#import "GraphDataSource.h"
#import "GraphTimeInterval.h"
#import "GraphTimeIntervalPart.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphTitleAreaDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"
#import "GraphDateBarDescriptor.h"
#import "GraphsManager.h"

#pragma mark -

@interface GraphScrollableCell ()

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

- (void)setup;
- (void)setupVisualAppearanceWithDescriptor:(GraphVisualAppearanceDescriptor*)descriptor;
- (void)setupTitleAreaWithDescriptor:(GraphTitleAreaDescriptor*)descriptor;
- (void)setupMinMaxValuesWithDescriptor:(GraphDescriptor*)descriptor;

@property (nonatomic, assign) CGPoint layoutSubviewsContentOffset;

- (NSString*)stringForMinMaxValue:(double)minMaxValue;

@end

#pragma mark -

@implementation GraphScrollableCell

#pragma mark - Initializing

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;
    
    _layoutSubviewsContentOffset = CGPointZero;
    [self addObserver:self forKeyPath:@"graphDescriptor" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self addObserver:self forKeyPath:@"graphDescriptor.isDisabled" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    _layoutSubviewsContentOffset = CGPointZero;
    [self addObserver:self forKeyPath:@"graphDescriptor" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self addObserver:self forKeyPath:@"graphDescriptor.isDisabled" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)dealloc {
    [self removeGestureRecognizer:self.tapGestureRecognizer];
    [self removeObserver:self forKeyPath:@"graphDescriptor"];
    [self removeObserver:self forKeyPath:@"graphDescriptor.isDisabled"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    [self setup];
}

- (void)awakeFromNib {
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollableCellTapped:)];
    [self addGestureRecognizer:self.tapGestureRecognizer];
    
    [self.graphCollectionView registerNib:[UINib nibWithNibName:@"GraphCell" bundle:nil] forCellWithReuseIdentifier:@"GraphCell"];
    [self.graphCollectionView reloadData];
}

- (void)setup {
    if (self.graphDescriptor.displayAreaDescriptor.scalingMode == GraphScalingMode_Scale) {
        self.graphDescriptor.displayAreaDescriptor.minValue = self.graphDescriptor.dataSource.minValue;
        self.graphDescriptor.displayAreaDescriptor.maxValue = self.graphDescriptor.dataSource.maxValue;
        self.graphDescriptor.displayAreaDescriptor.midValue = self.graphDescriptor.dataSource.midValue;
    }
    
    [self setupVisualAppearanceWithDescriptor:self.graphDescriptor.visualAppearanceDescriptor];
    [self setupTitleAreaWithDescriptor:self.graphDescriptor.titleAreaDescriptor];
    [self setupMinMaxValuesWithDescriptor:self.graphDescriptor];
    
    [self.graphCollectionView.collectionViewLayout invalidateLayout];
    [self.graphCollectionView reloadData];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGPointEqualToPoint(self.layoutSubviewsContentOffset, CGPointZero) && self.graphCollectionView.contentSize.width > 0) {
        [self scrollToContentOffset:self.layoutSubviewsContentOffset animated:NO];
        self.layoutSubviewsContentOffset = CGPointZero;
    }
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

- (void)setupMinMaxValuesWithDescriptor:(GraphDescriptor*)descriptor {
    BOOL hasValues = (descriptor.dataSource.minValue != descriptor.dataSource.maxValue);
    
    self.minValueLabel.hidden = !hasValues;
    self.midValueLabel.hidden = !hasValues;
    self.maxValueLabel.hidden = !hasValues;
    
    if (hasValues) {
        self.minValueLabelBottomSpaceLayoutConstraint.constant = descriptor.displayAreaDescriptor.graphBarsBottomPadding + descriptor.dateBarDescriptor.dateBarHeight;
        self.minValueLabel.font = descriptor.displayAreaDescriptor.valuesFont;
        self.minValueLabel.textColor = descriptor.displayAreaDescriptor.valuesDisplayColor;
        self.minValueLabel.shadowColor = (self.graphDescriptor.isDisabled ? nil : [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1.0]);
        self.minValueLabel.shadowOffset = CGSizeMake(1.0, 1.0);
        self.minValueLabel.text = [self stringForMinMaxValue:descriptor.displayAreaDescriptor.minValue];
        
        self.maxValueLabelBottomSpaceLayoutConstraint.constant = descriptor.dateBarDescriptor.dateBarHeight + descriptor.displayAreaDescriptor.displayAreaHeight - descriptor.displayAreaDescriptor.valuesDisplayHeight - descriptor.displayAreaDescriptor.graphBarsTopPadding;
        self.maxValueLabel.font = descriptor.displayAreaDescriptor.valuesFont;
        self.maxValueLabel.textColor = descriptor.displayAreaDescriptor.valuesDisplayColor;
        self.maxValueLabel.shadowColor = (self.graphDescriptor.isDisabled ? nil : [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1.0]);
        self.maxValueLabel.shadowOffset = CGSizeMake(1.0, 1.0);
        self.maxValueLabel.text = [self stringForMinMaxValue:descriptor.displayAreaDescriptor.maxValue];
        
        self.midValueLabelBottomSpaceLayoutConstraint.constant = round((self.minValueLabelBottomSpaceLayoutConstraint.constant + self.maxValueLabelBottomSpaceLayoutConstraint.constant) / 2.0);
        self.midValueLabel.font = descriptor.displayAreaDescriptor.valuesFont;
        self.midValueLabel.textColor = descriptor.displayAreaDescriptor.valuesDisplayColor;
        self.midValueLabel.shadowColor = (self.graphDescriptor.isDisabled ? nil : [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1.0]);
        self.midValueLabel.shadowOffset = CGSizeMake(1.0, 1.0);
        self.midValueLabel.text = [self stringForMinMaxValue:descriptor.displayAreaDescriptor.midValue];
    }
}

#pragma mark - Utils

- (void)scrollToContentOffset:(CGPoint)contentOffset animated:(BOOL)animate {
    id graphCollectionViewDelegate = self.graphCollectionView.delegate;
    self.graphCollectionView.delegate = nil;
    [self.graphCollectionView setContentOffset:contentOffset animated:animate];
    self.graphCollectionView.delegate = graphCollectionViewDelegate;
}

- (void)scrollToContentOffsetInLayoutSubviews:(CGPoint)contentOffset {
    self.layoutSubviewsContentOffset = contentOffset;
}

- (void)scrollToCurrentDateAnimated:(BOOL)animate {
    if (!self.graphDescriptor.graphTimeInterval) return;
    NSInteger timeIntervalIndex = self.graphDescriptor.graphTimeInterval.currentDateTimeIntervalPartIndex;
    if (timeIntervalIndex == -1) return;
    
    id graphCollectionViewDelegate = self.graphCollectionView.delegate;
    self.graphCollectionView.delegate = nil;
    
    [self.graphCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:timeIntervalIndex inSection:0]
                                     atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                             animated:animate];
    
    self.graphCollectionView.delegate = graphCollectionViewDelegate;
}

- (void)stopScrolling {
    [self.graphCollectionView setContentOffset:self.graphCollectionView.contentOffset animated:NO];
}

- (NSString*)stringForMinMaxValue:(double)minMaxValue {
    double roundedMinMaxValue = round(minMaxValue);
    if (roundedMinMaxValue == minMaxValue) return [NSString stringWithFormat:@"%d",(int)minMaxValue];
    return [NSString stringWithFormat:@"%1.1lf",minMaxValue];
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

#pragma mark - Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    if (self.graphScrollableCellDelegate && [self.graphScrollableCellDelegate respondsToSelector:@selector(graphScrollableCell:didScrollToContentOffset:)]) {
        [self.graphScrollableCellDelegate graphScrollableCell:self didScrollToContentOffset:self.graphCollectionView.contentOffset];
    }
}

#pragma mark - Tap gesture recognizer

- (void)scrollableCellTapped:(UIGestureRecognizer*)gesture {
    if (self.graphScrollableCellDelegate && [self.graphScrollableCellDelegate respondsToSelector:@selector(graphScrollableCellTapped:)]) {
        [self.graphScrollableCellDelegate graphScrollableCellTapped:self];
    }
}

@end
