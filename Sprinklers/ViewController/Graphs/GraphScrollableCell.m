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
#import "GraphValuesBarDescriptor.h"
#import "GraphIconsBarDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"
#import "GraphDateBarDescriptor.h"
#import "GraphsManager.h"
#import "GraphView.h"
#import "GraphStyle.h"

#pragma mark -

@interface GraphScrollableCell ()

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

- (void)setup;
- (void)setupBackgroundGraphViewWithDescriptor:(GraphDescriptor*)descriptor;
- (void)setupValuesMetricWithDescriptor:(GraphDescriptor*)descriptor;
- (void)setupDateWithDescriptor:(GraphDescriptor*)descriptor;
- (void)setupVisualAppearanceWithDescriptor:(GraphVisualAppearanceDescriptor*)descriptor;
- (void)setupTitleAreaWithDescriptor:(GraphTitleAreaDescriptor*)descriptor;
- (void)setupMinMaxValuesWithDescriptor:(GraphDescriptor*)descriptor;

- (NSString*)stringForMinMaxValue:(double)minMaxValue;
- (void)updateDateLabelsForContentOffset;
- (void)updateDateLabelsForTimeIntervalPart:(GraphTimeIntervalPart*)timeIntervalPart andIndex:(NSInteger)index;

@end

#pragma mark -

@implementation GraphScrollableCell

#pragma mark - Initializing

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;
    
    [self addObserver:self forKeyPath:@"graphDescriptor" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self addObserver:self forKeyPath:@"graphDescriptor.isDisabled" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    [self addObserver:self forKeyPath:@"graphDescriptor" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self addObserver:self forKeyPath:@"graphDescriptor.isDisabled" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)dealloc {
    self.graphScrollableCellDelegate = nil;
    self.graphCollectionView.delegate = nil;
    self.graphCollectionView.dataSource = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
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
    
    self.backgroundGraphView.graphStyle = [GraphStyle new];
    self.backgroundGraphView.graphStyle.shouldDrawRaster = YES;
}

- (void)setup {
    if (self.graphDescriptor.displayAreaDescriptor.scalingMode == GraphScalingMode_Scale) {
        self.graphDescriptor.displayAreaDescriptor.minValue = self.graphDescriptor.dataSource.minValue;
        self.graphDescriptor.displayAreaDescriptor.maxValue = self.graphDescriptor.dataSource.maxValue;
        self.graphDescriptor.displayAreaDescriptor.midValue = self.graphDescriptor.dataSource.midValue;
    }
    
    [self setupBackgroundGraphViewWithDescriptor:self.graphDescriptor];
    [self setupValuesMetricWithDescriptor:self.graphDescriptor];
    [self setupDateWithDescriptor:self.graphDescriptor];
    [self setupVisualAppearanceWithDescriptor:self.graphDescriptor.visualAppearanceDescriptor];
    [self setupTitleAreaWithDescriptor:self.graphDescriptor.titleAreaDescriptor];
    [self setupMinMaxValuesWithDescriptor:self.graphDescriptor];
    
    [self.graphCollectionView.collectionViewLayout invalidateLayout];
    [self.graphCollectionView reloadData];
    
    [self updateDateLabelsForContentOffset];
}

#pragma mark - Visual appearance

- (void)setupBackgroundGraphViewWithDescriptor:(GraphDescriptor*)descriptor {
    self.backgroundGraphView.graphStyle.graphDescriptor = descriptor;
    self.backgroundGraphViewTopLayoutConstraint.constant = descriptor.totalGraphHeaderHeight;
    self.backgroundGraphViewBottomLayoutConstraint.constant = descriptor.totalGraphFooterHeight;
}

- (void)setupValuesMetricWithDescriptor:(GraphDescriptor*)descriptor {
    GraphValuesBarDescriptor *valuesBarDescriptor = [descriptor.valuesBarDescriptorsDictionary objectForKey:@(self.graphDescriptor.graphTimeInterval.type)];
    
    if (valuesBarDescriptor) {
        [valuesBarDescriptor reloadUnits];
        
        GraphIconsBarDescriptor *iconsBarDescriptor = [descriptor.iconsBarDescriptorsDictionary objectForKey:@(self.graphDescriptor.graphTimeInterval.type)];
        CGFloat valuesMetricLabelTopSpaceLayoutConstraintConstant = 0.0;
        if (iconsBarDescriptor) valuesMetricLabelTopSpaceLayoutConstraintConstant += iconsBarDescriptor.iconsBarHeight;
        self.valuesMetricLabelTopSpaceLayoutConstraint.constant = valuesMetricLabelTopSpaceLayoutConstraintConstant;
        self.valuesMetricLabelHeightLayoutConstraint.constant = valuesBarDescriptor.valuesBarHeight;
        
        self.valuesMetricLabel.text = valuesBarDescriptor.units;
        self.valuesMetricLabel.textColor = valuesBarDescriptor.unitsColor;
        self.valuesMetricLabel.font = valuesBarDescriptor.unitsFont;
    }
    
    self.valuesMetricLabel.hidden = !valuesBarDescriptor;
}

- (void)setupDateWithDescriptor:(GraphDescriptor*)descriptor {
    GraphDateBarDescriptor *dateBarDescriptor = descriptor.dateBarDescriptor;
    
    CGFloat dateBarTotalHeight = 0.0;
    if (descriptor.graphTimeInterval.type != GraphTimeIntervalType_Weekly) dateBarTotalHeight = dateBarDescriptor.dateBarHeight;
    else dateBarTotalHeight = [dateBarDescriptor totalBarHeightForGraphTimeInterval:descriptor.graphTimeInterval];
    
    self.dateLabelTopHeightLayoutConstraint.constant = dateBarDescriptor.weekdaysBarHeight;
    self.dateLabelTopBottomSpaceLayoutConstraint.constant = dateBarTotalHeight - dateBarDescriptor.weekdaysBarHeight;
    self.dateLabelTop.textColor = dateBarDescriptor.dateValuesColor;
    self.dateLabelTop.font = dateBarDescriptor.dateValuesFont;
    
    self.dateLabelBottomHeightLayoutConstraint.constant = dateBarDescriptor.dateBarHeight - dateBarDescriptor.dateBarBottomPadding;
    self.dateLabelBottomBottomSpaceLayoutConstraint.constant = dateBarDescriptor.dateBarBottomPadding;
    self.dateLabelBottom.textColor = dateBarDescriptor.dateValuesColor;
    self.dateLabelBottom.font = dateBarDescriptor.dateValuesFont;
    
    self.dateLabelTop.hidden = (!dateBarDescriptor.hasWeekdaysBar || descriptor.graphTimeInterval.type != GraphTimeIntervalType_Weekly);
}

- (void)setupVisualAppearanceWithDescriptor:(GraphVisualAppearanceDescriptor*)descriptor {
    self.graphContainerView.backgroundColor = descriptor.backgroundColor;
    if (descriptor.cornerRadius > 0.0) self.graphContainerView.layer.cornerRadius = descriptor.cornerRadius;
    else self.graphContainerView.layer.cornerRadius = 0.0;
}

- (void)setupTitleAreaWithDescriptor:(GraphTitleAreaDescriptor*)descriptor {
    [descriptor reloadUnits];
    
    self.titleAreaContainerViewHeightLayoutConstraint.constant = descriptor.titleAreaHeight;
    self.titleAreaSeparatorView.backgroundColor = descriptor.titleAreaSeparatorColor;
    self.graphTitleLabel.text = descriptor.title;
    self.graphTitleLabel.textColor = descriptor.titleColor;
    self.graphTitleLabel.font = descriptor.titleFont;
    self.graphUnitsLabel.text = descriptor.units;
    self.graphUnitsLabel.textColor = descriptor.unitsColor;
    self.graphUnitsLabel.font = descriptor.unitsFont;
    self.graphUnitsLabelWidthLayoutConstraint.constant = self.graphDescriptor.titleAreaDescriptor.unitsWidth;
}

- (void)setupMinMaxValuesWithDescriptor:(GraphDescriptor*)descriptor {
    BOOL hasValues = (descriptor.dataSource.minValue != descriptor.dataSource.maxValue);
    
    self.minValueLabel.hidden = !hasValues;
    self.midValueLabel.hidden = !hasValues;
    self.maxValueLabel.hidden = !hasValues;
    
    if (hasValues) {
        CGFloat totalDateBarHeight = [self.graphDescriptor.dateBarDescriptor totalBarHeightForGraphTimeInterval:self.graphDescriptor.graphTimeInterval];
        
        self.minValueLabelBottomSpaceLayoutConstraint.constant = descriptor.displayAreaDescriptor.graphBarsBottomPadding + totalDateBarHeight;
        self.minValueLabel.font = descriptor.displayAreaDescriptor.valuesFont;
        self.minValueLabel.textColor = descriptor.displayAreaDescriptor.valuesDisplayColor;
        self.minValueLabel.shadowColor = (self.graphDescriptor.isDisabled && !self.graphDescriptor.dontShowDisabledState ? nil : [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1.0]);
        self.minValueLabel.shadowOffset = CGSizeMake(1.0, 1.0);
        self.minValueLabel.text = [self stringForMinMaxValue:descriptor.displayAreaDescriptor.minValue];
        
        self.maxValueLabelBottomSpaceLayoutConstraint.constant = totalDateBarHeight + descriptor.displayAreaDescriptor.displayAreaHeight - descriptor.displayAreaDescriptor.valuesDisplayHeight - descriptor.displayAreaDescriptor.graphBarsTopPadding;
        self.maxValueLabel.font = descriptor.displayAreaDescriptor.valuesFont;
        self.maxValueLabel.textColor = descriptor.displayAreaDescriptor.valuesDisplayColor;
        self.maxValueLabel.shadowColor = (self.graphDescriptor.isDisabled && !self.graphDescriptor.dontShowDisabledState  ? nil : [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1.0]);
        self.maxValueLabel.shadowOffset = CGSizeMake(1.0, 1.0);
        self.maxValueLabel.text = [self stringForMinMaxValue:descriptor.displayAreaDescriptor.maxValue];
        
        self.midValueLabelBottomSpaceLayoutConstraint.constant = round((self.minValueLabelBottomSpaceLayoutConstraint.constant + self.maxValueLabelBottomSpaceLayoutConstraint.constant) / 2.0);
        self.midValueLabel.font = descriptor.displayAreaDescriptor.valuesFont;
        self.midValueLabel.textColor = descriptor.displayAreaDescriptor.valuesDisplayColor;
        self.midValueLabel.shadowColor = (self.graphDescriptor.isDisabled && !self.graphDescriptor.dontShowDisabledState  ? nil : [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1.0]);
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
    
    [self performSelector:@selector(updateDateLabelsForContentOffset)
               withObject:nil
               afterDelay:0.0
                  inModes:@[NSRunLoopCommonModes]];
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
    
    if (timeIntervalIndex < self.graphDescriptor.graphTimeInterval.graphTimeIntervalParts.count) {
        GraphTimeIntervalPart *graphTimeIntervalPart = self.graphDescriptor.graphTimeInterval.graphTimeIntervalParts[timeIntervalIndex];
        [self updateDateLabelsForTimeIntervalPart:graphTimeIntervalPart andIndex:0];
    }
}

- (void)stopScrolling {
    [self.graphCollectionView setContentOffset:self.graphCollectionView.contentOffset animated:NO];
}

- (NSString*)stringForMinMaxValue:(double)minMaxValue {
    double roundedMinMaxValue = round(minMaxValue);
    if (roundedMinMaxValue == minMaxValue) return [NSString stringWithFormat:@"%d",(int)minMaxValue];

    NSString *fractionDecimalsString = [NSString stringWithFormat:@"%d",(int)self.graphDescriptor.displayAreaDescriptor.minMaxFractionDecimals];
    NSString *formatString = [[@"%1." stringByAppendingString:fractionDecimalsString] stringByAppendingString:@"lf"];
    NSString *stringValue = [NSString stringWithFormat:formatString,minMaxValue];
    
    while (stringValue.length && [stringValue characterAtIndex:stringValue.length - 1] == '0') stringValue = [stringValue substringToIndex:stringValue.length - 1];
    if (stringValue.length && [stringValue characterAtIndex:stringValue.length - 1] == '.') stringValue = [stringValue substringToIndex:stringValue.length - 1];
    
    return stringValue;
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
    [self updateDateLabelsForContentOffset];
}

- (void)updateDateLabelsForContentOffset {
    GraphCell *firstVisibleCell = nil;
    for (GraphCell *visibleCell in self.graphCollectionView.visibleCells) {
        if (!firstVisibleCell) firstVisibleCell = visibleCell;
        else if (visibleCell.frame.origin.x < firstVisibleCell.frame.origin.x) {
            firstVisibleCell = visibleCell;
        }
    }
    
    if (firstVisibleCell) {
        NSArray *coordinatesX = firstVisibleCell.graphView.graphStyle.coordinatesX;
        NSInteger index = 0;
        for (NSNumber *coordinateX in coordinatesX) {
            if (self.graphCollectionView.contentOffset.x < firstVisibleCell.frame.origin.x + coordinateX.doubleValue) break;
            index++;
        }
        
        if (index >= coordinatesX.count && coordinatesX.count) index = coordinatesX.count - 1;
        
        [self updateDateLabelsForTimeIntervalPart:firstVisibleCell.graphTimeIntervalPart andIndex:index];
    }
}

- (void)updateDateLabelsForTimeIntervalPart:(GraphTimeIntervalPart*)timeIntervalPart andIndex:(NSInteger)index {
    NSString *monthValue = (timeIntervalPart.monthValues.count > index ? timeIntervalPart.monthValues[index] : nil);
    NSString *yearValue = (timeIntervalPart.yearValues.count > index ? timeIntervalPart.yearValues[index] : nil);
    
    if (monthValue && yearValue) {
        if (!self.dateLabelTop.hidden) {
            self.dateLabelTop.text = monthValue;
            self.dateLabelBottom.text = yearValue;
        } else {
            self.dateLabelTop.text = nil;
            self.dateLabelBottom.text = [NSString stringWithFormat:@"%@'%@",monthValue,[yearValue substringFromIndex:2]];
        }
    } else {
        self.dateLabelTop.text = nil;
        if (monthValue) self.dateLabelBottom.text = monthValue;
        else if (yearValue) self.dateLabelBottom.text = yearValue;
    }
}

#pragma mark - Tap gesture recognizer

- (void)scrollableCellTapped:(UIGestureRecognizer*)gesture {
    if (self.graphScrollableCellDelegate && [self.graphScrollableCellDelegate respondsToSelector:@selector(graphScrollableCellTapped:)]) {
        [self.graphScrollableCellDelegate graphScrollableCellTapped:self];
    }
}

@end
