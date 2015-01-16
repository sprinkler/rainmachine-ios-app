//
//  GraphCell.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphCell.h"
#import "GraphView.h"
#import "GraphDescriptor.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphIconsBarDescriptor.h"
#import "GraphValuesBarDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"
#import "GraphDateBarDescriptor.h"
#import "GraphStyle.h"
#import "GraphTimeInterval.h"
#import "GraphDataSource.h"
#import "Additions.h"
#import "Utils.h"

#pragma mark -

@interface GraphCell ()

- (void)setup;
- (void)setupIconImagesWithDescriptor:(GraphIconsBarDescriptor*)descriptor dataSource:(GraphDataSource*)dataSource;
- (void)setupValuesWithDescriptor:(GraphValuesBarDescriptor*)descriptor dataSource:(GraphDataSource*)dataSource;
- (void)setupDisplayAreaWithDescriptor:(GraphDisplayAreaDescriptor*)descriptor;
- (void)setupDatesWithDescriptor:(GraphDateBarDescriptor*)descriptor;
- (void)setupCurrentDateWithDescriptor:(GraphDateBarDescriptor*)descriptor;

@property (nonatomic, strong) NSArray *iconImageViews;
@property (nonatomic, strong) NSArray *valueLabels;
@property (nonatomic, strong) NSArray *dateValueLabels;
@property (nonatomic, strong) UIView *dateSelectionView;

- (void)updateMinMaxValuesFromValues:(NSArray*)values;
- (void)hideShowInterfaceComponents;

@property (nonatomic, strong) NSArray *dataSourceValues;
@property (nonatomic, strong) NSArray *dataSourceTopValues;
@property (nonatomic, strong) NSArray *dataSourceIconImageIndexes;

- (UIImage*)iconImageForIconImageIndex:(id)iconImageIndex;

@end

#pragma mark -

@implementation GraphCell

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

#pragma mark - Helper methods

- (void)setup {
    self.dataSourceValues = [self.graphDescriptor.graphTimeInterval timeIntervalRestrictedValuesForGraphDataSource:self.graphDescriptor.dataSource];
    
    if (self.graphDescriptor.graphTimeInterval && self.graphDescriptor.valuesBarDescriptorsDictionary[@(self.graphDescriptor.graphTimeInterval.type)]) {
        self.dataSourceTopValues = [self.graphDescriptor.graphTimeInterval timeIntervalRestrictedTopValuesForGraphDataSource:self.graphDescriptor.dataSource];
    } else {
        self.dataSourceTopValues = nil;
    }

    if (self.graphDescriptor.graphTimeInterval && self.graphDescriptor.iconsBarDescriptorsDictionary[@(self.graphDescriptor.graphTimeInterval.type)]) {
        self.dataSourceIconImageIndexes = [self.graphDescriptor.graphTimeInterval timeIntervalRestrictedIconImageIndexesForGraphDataSource:self.graphDescriptor.dataSource];
    } else {
        self.dataSourceIconImageIndexes = nil;
    }
    
    if (self.graphDescriptor.displayAreaDescriptor.scalingMode == GraphScalingMode_Scale) {
        [self updateMinMaxValuesFromValues:self.dataSourceValues];
    }
    
    self.graphContainerView.backgroundColor = [UIColor clearColor];
    
    GraphIconsBarDescriptor *iconsBarDescriptor = (self.graphDescriptor.graphTimeInterval ? self.graphDescriptor.iconsBarDescriptorsDictionary[@(self.graphDescriptor.graphTimeInterval.type)] : nil);
    GraphValuesBarDescriptor *valuesBarDescriptor = (self.graphDescriptor.graphTimeInterval ? self.graphDescriptor.valuesBarDescriptorsDictionary[@(self.graphDescriptor.graphTimeInterval.type)] : nil);

    [self setupIconImagesWithDescriptor:iconsBarDescriptor dataSource:self.graphDescriptor.dataSource];
    [self setupValuesWithDescriptor:valuesBarDescriptor dataSource:self.graphDescriptor.dataSource];
    
    [self setupDisplayAreaWithDescriptor:self.graphDescriptor.displayAreaDescriptor];
    [self setupDatesWithDescriptor:self.graphDescriptor.dateBarDescriptor];
    
    [self.graphView setNeedsDisplay];
    
    [self hideShowInterfaceComponents];
}

- (void)updateMinMaxValuesFromValues:(NSArray*)values {
    if (!values.count) return;
    
    double minValue = 0.0;
    double maxValue = 0.0;
    
    BOOL minValueSet = NO;
    BOOL maxValueSet = NO;
    
    for (id value in values) {
        if (value == [NSNull null]) continue;
        NSNumber *numberValue = (NSNumber*)value;
        
        if (!minValueSet) minValue = numberValue.doubleValue;
        if (!maxValueSet) maxValue = numberValue.doubleValue;
        minValueSet = maxValueSet = YES;
        
        if (numberValue.doubleValue < minValue) minValue = floor(numberValue.doubleValue);
        if (numberValue.doubleValue > maxValue) maxValue = ceil(numberValue.doubleValue);
    }
    
    if (minValue == maxValue) {
        if (maxValue > 0.0) minValue = 0.0;
        else if (maxValue < 0.0) maxValue = 0.0;
        else {
            maxValue = 1.0;
            minValue = - 1.0;
        }
    }
    
    double midValue = (minValue + maxValue) / 2.0;
    
    self.graphDescriptor.displayAreaDescriptor.minValue = minValue;
    self.graphDescriptor.displayAreaDescriptor.maxValue = maxValue;
    self.graphDescriptor.displayAreaDescriptor.midValue = midValue;
}

- (void)hideShowInterfaceComponents {
    BOOL hasValues = NO;
    for (id value in self.graphDescriptor.dataSource.values) {
        if (value != [NSNull null]) {
            hasValues = YES;
            break;
        }
    }
    
    self.emptyGraphLabel.hidden = hasValues;
    self.iconsBarContainerView.hidden = !hasValues;
    self.valuesBarContainerView.hidden = !hasValues;
    self.valuesUnitsLabel.hidden = !hasValues;
}

- (void)setupIconImagesWithDescriptor:(GraphIconsBarDescriptor*)descriptor dataSource:(GraphDataSource*)dataSource {
    if (!descriptor) {
        self.iconsBarContainerViewHeightLayoutConstraint.constant = 0.0;
        for (UIImageView *iconImageView in self.iconImageViews) {
            [iconImageView removeFromSuperview];
        }
        self.iconImageViews = nil;
        return;
    }
    
    if (self.iconImageViews) {
        for (NSInteger index = 0; index < self.dataSourceIconImageIndexes.count; index++) {
            UIImageView *iconImageView = self.iconImageViews[index];
            UIImage *iconImage = [self iconImageForIconImageIndex:self.dataSourceIconImageIndexes[index]];
            iconImageView.image = iconImage;
        }
        return;
    }
    
    self.iconsBarContainerViewHeightLayoutConstraint.constant = descriptor.iconsBarHeight;
    
    CGFloat totalPaddingWidth = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding + self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
    CGFloat totalIconBarWidth = self.iconsBarContainerView.bounds.size.width - totalPaddingWidth;
    CGFloat iconImageViewWidth = round(totalIconBarWidth / self.dataSourceIconImageIndexes.count);
    CGFloat iconImageViewHeight = descriptor.iconsHeight;
    
    CGFloat iconImageViewOriginX = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding;
    CGFloat iconImageViewOriginY = ceil((descriptor.iconsBarHeight - descriptor.iconsHeight) / 2.0);
    UIImageView *previousIconImageView = nil;
    
    BOOL isFirstHorizontalConstraint = YES;
    BOOL isLastHorizontalConstraint = NO;
    
    NSMutableArray *iconImageViews = [NSMutableArray new];
    
    NSInteger index = 0;
    for (id iconImageIndex in self.dataSourceIconImageIndexes) {
        isLastHorizontalConstraint = (index++ == self.dataSourceIconImageIndexes.count - 1);
        
        UIImageView *iconImageView = [[UIImageView alloc] initWithImage:[self iconImageForIconImageIndex:iconImageIndex]];
        iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
        iconImageView.frame = CGRectMake(iconImageViewOriginX, iconImageViewOriginY, iconImageViewWidth, iconImageViewHeight);
        iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.iconsBarContainerView addSubview:iconImageView];
        [iconImageViews addObject:iconImageView];
        
        if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
            if (previousIconImageView) {
                if (isFirstHorizontalConstraint) [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousIconImageView(==iconImageView)]-0-[iconImageView(==previousIconImageView)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousIconImageView,iconImageView)]];
                else if (isLastHorizontalConstraint) [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousIconImageView(==iconImageView)]-0-[iconImageView(==previousIconImageView)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousIconImageView,iconImageView)]];
                else [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousIconImageView(==iconImageView)]-0-[iconImageView(==previousIconImageView)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousIconImageView,iconImageView)]];
                isFirstHorizontalConstraint = NO;
            }
            [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%lf-[iconImageView(%lf)]",iconImageViewOriginY,iconImageViewHeight] options:0 metrics:nil views:NSDictionaryOfVariableBindings(iconImageView)]];
        } else {
            if (previousIconImageView) {
                if (isFirstHorizontalConstraint) [self.iconsBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousIconImageView(==iconImageView)]-0-[iconImageView(==previousIconImageView)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousIconImageView,iconImageView)]];
                else if (isLastHorizontalConstraint) [self.iconsBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousIconImageView(==iconImageView)]-0-[iconImageView(==previousIconImageView)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousIconImageView,iconImageView)]];
                else [self.iconsBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousIconImageView(==iconImageView)]-0-[iconImageView(==previousIconImageView)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousIconImageView,iconImageView)]];
                isFirstHorizontalConstraint = NO;
            }
            [self.iconsBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%lf-[iconImageView(%lf)]",iconImageViewOriginY,iconImageViewHeight] options:0 metrics:nil views:NSDictionaryOfVariableBindings(iconImageView)]];
        }
        
        previousIconImageView = iconImageView;
        iconImageViewOriginX += iconImageViewWidth;
    }
    
    self.iconImageViews = iconImageViews;
}

- (void)setupValuesWithDescriptor:(GraphValuesBarDescriptor*)descriptor dataSource:(GraphDataSource*)dataSource {
    if (!descriptor) {
        self.valuesBarContainerViewHeightLayoutConstraint.constant = 0.0;
        for (UILabel *valueLabel in self.valueLabels) {
            [valueLabel removeFromSuperview];
        }
        self.valueLabels = nil;
        return;
    }
    
    if (self.valueLabels) {
        for (NSInteger index = 0; index < self.dataSourceTopValues.count; index++) {
            id value = self.dataSourceTopValues[index];
            UILabel *valueLabel = self.valueLabels[index];
            valueLabel.text = (value == [NSNull null] ? nil : [NSString stringWithFormat:@"%1.1lf",((NSNumber*)value).doubleValue]);
        }
        return;
    }
    
    self.valuesBarContainerViewHeightLayoutConstraint.constant = descriptor.valuesBarHeight;
    
    CGFloat totalPaddingWidth = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding + self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
    CGFloat totalValuesBarWidth = self.valuesBarContainerView.bounds.size.width - totalPaddingWidth;
    CGFloat valueLabelWidth = round(totalValuesBarWidth / self.dataSourceTopValues.count);
    CGFloat valueLabelHeight = descriptor.valuesBarHeight;
    
    CGFloat valueLabelOriginX = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding;
    CGFloat valueLabelOriginY = 0.0;
    UILabel *previousValueLabel = nil;
    
    BOOL isFirstHorizontalConstraint = YES;
    BOOL isLastHorizontalConstraint = NO;
    
    NSMutableArray *valueLabels = [NSMutableArray new];
    
    NSInteger index = 0;
    for (id value in self.dataSourceTopValues) {
        isLastHorizontalConstraint = (index++ == self.dataSourceTopValues.count - 1);
        
        UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(valueLabelOriginX, valueLabelOriginY, valueLabelWidth, valueLabelHeight)];
        valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        valueLabel.text = (value == [NSNull null] ? nil : [NSString stringWithFormat:@"%1.1lf",((NSNumber*)value).doubleValue]);
        valueLabel.textColor = descriptor.valuesColor;
        valueLabel.font = descriptor.valuesFont;
        valueLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.valuesBarContainerView addSubview:valueLabel];
        [valueLabels addObject:valueLabel];
        
        if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
            if (previousValueLabel) {
                if (isFirstHorizontalConstraint) [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousValueLabel(==valueLabel)]-0-[valueLabel(==previousValueLabel)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousValueLabel,valueLabel)]];
                else if (isLastHorizontalConstraint) [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousValueLabel(==valueLabel)]-0-[valueLabel(==previousValueLabel)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousValueLabel,valueLabel)]];
                else [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousValueLabel(==valueLabel)]-0-[valueLabel(==previousValueLabel)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousValueLabel,valueLabel)]];
                isFirstHorizontalConstraint = NO;
            }
            [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%lf-[valueLabel(%lf)]",valueLabelOriginY,valueLabelHeight] options:0 metrics:nil views:NSDictionaryOfVariableBindings(valueLabel)]];
        } else {
            if (previousValueLabel) {
                if (isFirstHorizontalConstraint) [self.valuesBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousValueLabel(==valueLabel)]-0-[valueLabel(==previousValueLabel)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousValueLabel,valueLabel)]];
                else if (isLastHorizontalConstraint) [self.valuesBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousValueLabel(==valueLabel)]-0-[valueLabel(==previousValueLabel)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousValueLabel,valueLabel)]];
                else [self.valuesBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousValueLabel(==valueLabel)]-0-[valueLabel(==previousValueLabel)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousValueLabel,valueLabel)]];
                isFirstHorizontalConstraint = NO;
            }
            [self.valuesBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%lf-[valueLabel(%lf)]",valueLabelOriginY,valueLabelHeight] options:0 metrics:nil views:NSDictionaryOfVariableBindings(valueLabel)]];
        }
        
        previousValueLabel = valueLabel;
        valueLabelOriginX += valueLabelWidth;
    }
    
    self.valueLabels = valueLabels;
    
    self.valuesUnitsLabel.text = descriptor.units;
    self.valuesUnitsLabel.textColor = descriptor.unitsColor;
    self.valuesUnitsLabel.font = descriptor.unitsFont;
    self.valuesUnitsLabelWidthLayoutConstraint.constant = self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
}

- (void)setupDisplayAreaWithDescriptor:(GraphDisplayAreaDescriptor*)descriptor {
    self.graphViewHeightLayoutConstraint.constant = descriptor.displayAreaHeight;
    self.graphView.graphStyle = descriptor.graphStyle;
    self.graphView.graphStyle.graphDescriptor = self.graphDescriptor;
    self.graphView.graphStyle.values = self.dataSourceValues;
    [self.graphView setNeedsDisplay];
}

- (void)setupDatesWithDescriptor:(GraphDateBarDescriptor*)descriptor {
    if (!descriptor) {
        self.dateBarContainerViewHeightLayoutConstraint.constant = 0.0;
        return;
    }
    
    if (self.dateValueLabels) {
        for (NSInteger index = 0; index < descriptor.dateValues.count; index++) {
            UILabel *dateValueLabel = self.dateValueLabels[index];
            NSString *dateValue = descriptor.dateValues[index];
            dateValueLabel.text = dateValue;
        }
        
        self.timeIntervalLabel.text = descriptor.timeIntervalValue;
        [self setupCurrentDateWithDescriptor:descriptor];
        
        return;
    }
    
    self.dateBarContainerViewHeightLayoutConstraint.constant = descriptor.dateBarHeight;
    
    CGFloat totalPaddingWidth = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding + self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
    CGFloat totalDatesBarWidth = self.dateBarContainerView.bounds.size.width - totalPaddingWidth;
    CGFloat dateValueLabelWidth = round(totalDatesBarWidth / descriptor.dateValues.count);
    CGFloat dateValueLabelHeight = descriptor.dateBarHeight - descriptor.dateBarBottomPadding;
    
    CGFloat dateValueLabelOriginX = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding;
    CGFloat dateValueLabelOriginY = 0.0;
    UILabel *previousDateValueLabel = nil;
    
    BOOL isFirstHorizontalConstraint = YES;
    BOOL isLastHorizontalConstraint = NO;
    
    NSMutableArray *dateValueLabels = [NSMutableArray new];
    
    for (NSString *dateValue in descriptor.dateValues) {
        isLastHorizontalConstraint = (dateValue == descriptor.dateValues.lastObject);
        
        UILabel *dateValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(dateValueLabelOriginX, dateValueLabelOriginY, dateValueLabelWidth, dateValueLabelHeight)];
        dateValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        dateValueLabel.text = dateValue;
        dateValueLabel.textColor = descriptor.dateValuesColor;
        dateValueLabel.font = descriptor.dateValuesFont;
        dateValueLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.dateBarContainerView addSubview:dateValueLabel];
        [dateValueLabels addObject:dateValueLabel];
        
        if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
            if (previousDateValueLabel) {
                if (isFirstHorizontalConstraint) [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousDateValueLabel(==dateValueLabel)]-0-[dateValueLabel(==previousDateValueLabel)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousDateValueLabel,dateValueLabel)]];
                else if (isLastHorizontalConstraint) [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousDateValueLabel(==dateValueLabel)]-0-[dateValueLabel(==previousDateValueLabel)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousDateValueLabel,dateValueLabel)]];
                else [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousDateValueLabel(==dateValueLabel)]-0-[dateValueLabel(==previousDateValueLabel)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousDateValueLabel,dateValueLabel)]];
                isFirstHorizontalConstraint = NO;
            }
            [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%lf-[dateValueLabel(%lf)]",dateValueLabelOriginY,dateValueLabelHeight] options:0 metrics:nil views:NSDictionaryOfVariableBindings(dateValueLabel)]];
        } else {
            if (previousDateValueLabel) {
                if (isFirstHorizontalConstraint) [self.dateBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousDateValueLabel(==dateValueLabel)]-0-[dateValueLabel(==previousDateValueLabel)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousDateValueLabel,dateValueLabel)]];
                else if (isLastHorizontalConstraint) [self.dateBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousDateValueLabel(==dateValueLabel)]-0-[dateValueLabel(==previousDateValueLabel)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousDateValueLabel,dateValueLabel)]];
                else [self.dateBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousDateValueLabel(==dateValueLabel)]-0-[dateValueLabel(==previousDateValueLabel)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousDateValueLabel,dateValueLabel)]];
                isFirstHorizontalConstraint = NO;
            }
            [self.dateBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%lf-[dateValueLabel(%lf)]",dateValueLabelOriginY,dateValueLabelHeight] options:0 metrics:nil views:NSDictionaryOfVariableBindings(dateValueLabel)]];
        }
        
        previousDateValueLabel = dateValueLabel;
        dateValueLabelOriginX += dateValueLabelWidth;
    }
    
    self.dateValueLabels = dateValueLabels;
    
    self.timeIntervalLabel.text = descriptor.timeIntervalValue;
    self.timeIntervalLabel.textColor = descriptor.timeIntervalColor;
    self.timeIntervalLabel.font = descriptor.timeIntervalFont;
    self.timeIntervalLabelWidthLayoutConstraint.constant = self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
    
    [self setupCurrentDateWithDescriptor:descriptor];
}

- (void)setupCurrentDateWithDescriptor:(GraphDateBarDescriptor*)descriptor {
    if (!self.dateSelectionView) {
        self.dateSelectionView = [[UIView alloc] initWithFrame:CGRectZero];
        self.dateSelectionView.backgroundColor = [UIColor clearColor];
        self.dateSelectionView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        self.dateSelectionView.layer.borderColor = descriptor.dateValueSelectionColor.CGColor;
        
        [self.dateBarContainerView addSubview:self.dateSelectionView];
    }
    
    if (descriptor.selectedDateValueIndex != -1 && descriptor.dateValues.count) {
        CGFloat totalPaddingWidth = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding + self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
        CGFloat totalDatesBarWidth = self.dateBarContainerView.bounds.size.width - totalPaddingWidth;
        
        UILabel *selectedDateLabel = self.dateValueLabels[descriptor.selectedDateValueIndex];
        CGSize dateSelectionViewBoundingSize = CGSizeZero;
        
        if ([[UIDevice currentDevice] iOSGreaterThan:7.0]) {
            dateSelectionViewBoundingSize = [selectedDateLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT)
                                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                                              attributes:@{NSFontAttributeName : selectedDateLabel.font}
                                                                                 context:nil].size;
        } else {
            dateSelectionViewBoundingSize = [selectedDateLabel.text sizeWithFont:selectedDateLabel.font
                                                               constrainedToSize:CGSizeMake(MAXFLOAT, MAXFLOAT)
                                                                   lineBreakMode:NSLineBreakByWordWrapping];
        }
        
        if (dateSelectionViewBoundingSize.width < 16.0) dateSelectionViewBoundingSize.width = 16.0;
        else dateSelectionViewBoundingSize.width = dateSelectionViewBoundingSize.width + 4.0;
        
        self.dateSelectionView.hidden = NO;
        self.dateSelectionView.frame = CGRectMake(0.0, 0.0, dateSelectionViewBoundingSize.width, descriptor.dateBarHeight - 2.0);
        self.dateSelectionView.center = CGPointMake(round(totalDatesBarWidth / descriptor.dateValues.count * (descriptor.selectedDateValueIndex + 0.5)) + self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding, round((descriptor.dateBarHeight - descriptor.dateBarBottomPadding) / 2.0));
    } else {
        self.dateSelectionView.hidden = YES;
    }
}

- (UIImage*)iconImageForIconImageIndex:(id)iconImageIndex {
    UIImage *image = [UIImage imageNamed:@"na_small_white"];
    if (iconImageIndex != [NSNull null]) image = [Utils smallWhiteWeatherImageFromCode:(NSNumber*)iconImageIndex];
    return [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:image.imageOrientation];
}

@end
