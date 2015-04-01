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
#import "GraphTitleAreaDescriptor.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphIconsBarDescriptor.h"
#import "GraphValuesBarDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"
#import "GraphDateBarDescriptor.h"
#import "GraphStyle.h"
#import "GraphTimeInterval.h"
#import "GraphTimeIntervalPart.h"
#import "GraphDataSource.h"
#import "Additions.h"
#import "Constants.h"
#import "Utils.h"

#pragma mark -

@interface GraphCell ()

- (void)setup;
- (void)setupIconImagesWithDescriptor:(GraphIconsBarDescriptor*)descriptor dataSource:(GraphDataSource*)dataSource;
- (void)setupValuesWithDescriptor:(GraphValuesBarDescriptor*)descriptor dataSource:(GraphDataSource*)dataSource;
- (void)setupDisplayAreaWithDescriptor:(GraphDisplayAreaDescriptor*)descriptor;
- (void)setupDatesWithDescriptor:(GraphDateBarDescriptor*)descriptor timeIntervalType:(GraphTimeIntervalPart*)timeIntervalPart;
- (void)setupWeekdaysWithDescriptor:(GraphDateBarDescriptor*)descriptor timeIntervalType:(GraphTimeIntervalPart*)timeIntervalPart;
- (void)setupCurrentDateWithDescriptor:(GraphDateBarDescriptor*)descriptor timeIntervalPart:(GraphTimeIntervalPart*)timeIntervalPart;

@property (nonatomic, strong) NSArray *iconImageViews;
@property (nonatomic, strong) NSArray *valueLabels;
@property (nonatomic, strong) NSArray *weekdayLabels;
@property (nonatomic, strong) NSArray *dateValueLabels;
@property (nonatomic, strong) UIView *dateSelectionView;

@property (nonatomic, strong) NSArray *dataSourceValues;
@property (nonatomic, strong) id dataSourcePrevDateValue;
@property (nonatomic, strong) id dataSourceNextDateValue;
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
    
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"graphDescriptor"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    [self setup];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setupCurrentDateWithDescriptor:self.graphDescriptor.dateBarDescriptor timeIntervalPart:self.graphTimeIntervalPart];
}

#pragma mark - Helper methods

- (void)setup {
    id prevDateValue = nil;
    id nextDateValue = nil;
    self.dataSourceValues = [self.graphTimeIntervalPart timeIntervalRestrictedValuesForGraphDataSource:self.graphDescriptor.dataSource prevDateValue:&prevDateValue nextDateValue:&nextDateValue];
    self.dataSourcePrevDateValue = prevDateValue;
    self.dataSourceNextDateValue = nextDateValue;
    
    if (self.graphTimeIntervalPart && self.graphDescriptor.valuesBarDescriptorsDictionary[@(self.graphDescriptor.graphTimeInterval.type)]) {
        self.dataSourceTopValues = [self.graphTimeIntervalPart timeIntervalRestrictedTopValuesForGraphDataSource:self.graphDescriptor.dataSource];
    } else {
        self.dataSourceTopValues = nil;
    }

    if (self.graphDescriptor.graphTimeInterval && self.graphDescriptor.iconsBarDescriptorsDictionary[@(self.graphDescriptor.graphTimeInterval.type)]) {
        self.dataSourceIconImageIndexes = [self.graphTimeIntervalPart timeIntervalRestrictedIconImageIndexesForGraphDataSource:self.graphDescriptor.dataSource];
    } else {
        self.dataSourceIconImageIndexes = nil;
    }
    
    self.graphContainerView.backgroundColor = [UIColor clearColor];
    
    GraphIconsBarDescriptor *iconsBarDescriptor = (self.graphDescriptor.graphTimeInterval ? self.graphDescriptor.iconsBarDescriptorsDictionary[@(self.graphDescriptor.graphTimeInterval.type)] : nil);
    GraphValuesBarDescriptor *valuesBarDescriptor = (self.graphDescriptor.graphTimeInterval ? self.graphDescriptor.valuesBarDescriptorsDictionary[@(self.graphDescriptor.graphTimeInterval.type)] : nil);

    [self setupIconImagesWithDescriptor:iconsBarDescriptor dataSource:self.graphDescriptor.dataSource];
    [self setupValuesWithDescriptor:valuesBarDescriptor dataSource:self.graphDescriptor.dataSource];
    
    [self setupDisplayAreaWithDescriptor:self.graphDescriptor.displayAreaDescriptor];
    
    if (!self.graphDescriptor.dateBarDescriptor) self.dateBarContainerViewHeightLayoutConstraint.constant = 0.0;
    else {
        if (!self.graphTimeIntervalPart.weekdays.count) self.dateBarContainerViewHeightLayoutConstraint.constant = self.graphDescriptor.dateBarDescriptor.dateBarHeight;
        else self.dateBarContainerViewHeightLayoutConstraint.constant = [self.graphDescriptor.dateBarDescriptor totalBarHeightForGraphTimeInterval:self.graphDescriptor.graphTimeInterval];
        [self setupDatesWithDescriptor:self.graphDescriptor.dateBarDescriptor timeIntervalType:self.graphTimeIntervalPart];
        [self setupWeekdaysWithDescriptor:self.graphDescriptor.dateBarDescriptor timeIntervalType:self.graphTimeIntervalPart];
    }
    
    [self setupCurrentDateWithDescriptor:self.graphDescriptor.dateBarDescriptor timeIntervalPart:self.graphTimeIntervalPart];
    
    [self.graphView setNeedsDisplay];
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
            if (value == [NSNull null]) {
                valueLabel.text = nil;
            } else {
                switch (descriptor.valuesRoundingMode) {
                    case GraphValuesRoundingMode_None: valueLabel.text = [NSString stringWithFormat:@"%1.1lf",((NSNumber*)value).doubleValue]; break;
                    case GraphValuesRoundingMode_Round: valueLabel.text = [NSString stringWithFormat:@"%1.0lf",round(((NSNumber*)value).doubleValue)]; break;
                    case GraphValuesRoundingMode_Ceil: valueLabel.text = [NSString stringWithFormat:@"%1.0lf",ceil(((NSNumber*)value).doubleValue)]; break;
                    case GraphValuesRoundingMode_Floor: valueLabel.text = [NSString stringWithFormat:@"%1.0lf",floor(((NSNumber*)value).doubleValue)]; break;
                    default: valueLabel.text = nil;
                }
            }
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
        valueLabel.textColor = descriptor.valuesColor;
        valueLabel.font = descriptor.valuesFont;
        valueLabel.textAlignment = NSTextAlignmentCenter;
        
        if (value == [NSNull null]) {
            valueLabel.text = nil;
        } else {
            switch (descriptor.valuesRoundingMode) {
                case GraphValuesRoundingMode_None: valueLabel.text = [NSString stringWithFormat:@"%1.1lf",((NSNumber*)value).doubleValue]; break;
                case GraphValuesRoundingMode_Round: valueLabel.text = [NSString stringWithFormat:@"%1.0lf",round(((NSNumber*)value).doubleValue)]; break;
                case GraphValuesRoundingMode_Ceil: valueLabel.text = [NSString stringWithFormat:@"%1.0lf",ceil(((NSNumber*)value).doubleValue)]; break;
                case GraphValuesRoundingMode_Floor: valueLabel.text = [NSString stringWithFormat:@"%1.0lf",floor(((NSNumber*)value).doubleValue)]; break;
                default: valueLabel.text = nil;
            }
        }
        
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
    self.todaySelectionView.backgroundColor = descriptor.todaySelectionColor;
    self.todaySelectionViewWidthLayoutConstraint.constant = descriptor.todaySelectionWidth;
    
    self.graphViewHeightLayoutConstraint.constant = descriptor.displayAreaHeight;
    self.graphView.graphStyle = [descriptor.graphStyle copy];
    self.graphView.graphStyle.graphDescriptor = self.graphDescriptor;
    self.graphView.graphStyle.values = (self.graphDescriptor.dataSource.values ? self.dataSourceValues : nil);
    self.graphView.graphStyle.prevValue = self.dataSourcePrevDateValue;
    self.graphView.graphStyle.nextValue = self.dataSourceNextDateValue;
    
    [self.graphView setNeedsDisplay];
}

- (void)setupDatesWithDescriptor:(GraphDateBarDescriptor*)descriptor timeIntervalType:(GraphTimeIntervalPart*)timeIntervalPart {
    if (self.dateValueLabels) {
        for (NSInteger index = 0; index < timeIntervalPart.dateValues.count; index++) {
            UILabel *dateValueLabel = self.dateValueLabels[index];
            NSString *dateValue = timeIntervalPart.dateValues[index];
            dateValueLabel.text = dateValue;
        }
        return;
    }
    
    CGFloat totalPaddingWidth = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding + self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
    CGFloat totalDatesBarWidth = self.dateBarContainerView.bounds.size.width - totalPaddingWidth;
    CGFloat dateValueLabelWidth = round(totalDatesBarWidth / timeIntervalPart.dateValues.count);
    CGFloat dateValueLabelHeight = descriptor.dateBarHeight - descriptor.dateBarBottomPadding;
    
    CGFloat dateValueLabelOriginX = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding;
    UILabel *previousDateValueLabel = nil;
    
    BOOL isFirstHorizontalConstraint = YES;
    BOOL isLastHorizontalConstraint = NO;
    
    NSMutableArray *dateValueLabels = [NSMutableArray new];
    
    for (NSString *dateValue in timeIntervalPart.dateValues) {
        isLastHorizontalConstraint = (dateValue == timeIntervalPart.dateValues.lastObject);
        
        UILabel *dateValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
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
            [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[dateValueLabel(%lf)]-%lf-|",dateValueLabelHeight,descriptor.dateBarBottomPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(dateValueLabel)]];
        } else {
            if (previousDateValueLabel) {
                if (isFirstHorizontalConstraint) [self.dateBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousDateValueLabel(==dateValueLabel)]-0-[dateValueLabel(==previousDateValueLabel)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousDateValueLabel,dateValueLabel)]];
                else if (isLastHorizontalConstraint) [self.dateBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousDateValueLabel(==dateValueLabel)]-0-[dateValueLabel(==previousDateValueLabel)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousDateValueLabel,dateValueLabel)]];
                else [self.dateBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousDateValueLabel(==dateValueLabel)]-0-[dateValueLabel(==previousDateValueLabel)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousDateValueLabel,dateValueLabel)]];
                isFirstHorizontalConstraint = NO;
            }
            [self.dateBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[dateValueLabel(%lf)]-%lf-|",dateValueLabelHeight,descriptor.dateBarBottomPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(dateValueLabel)]];
        }
        
        previousDateValueLabel = dateValueLabel;
        dateValueLabelOriginX += dateValueLabelWidth;
    }
    
    self.dateValueLabels = dateValueLabels;
}

- (void)setupWeekdaysWithDescriptor:(GraphDateBarDescriptor*)descriptor timeIntervalType:(GraphTimeIntervalPart*)timeIntervalPart {
    if (![descriptor hasWeekdaysBarForGraphTimeInterval:self.graphDescriptor.graphTimeInterval] || !timeIntervalPart.weekdays.count) {
        if (self.weekdayLabels) {
            for (UILabel *weekdayLabel in self.weekdayLabels) {
                [weekdayLabel removeFromSuperview];
            }
        }
        self.weekdayLabels = nil;
        return;
    }
    
    if (self.weekdayLabels) {
        for (NSInteger index = 0; index < timeIntervalPart.dateValues.count; index++) {
            UILabel *weekdayLabel = self.weekdayLabels[index];
            NSString *weekday = timeIntervalPart.weekdays[index];
            weekdayLabel.text = weekday;
        }
        return;
    }
    
    CGFloat totalPaddingWidth = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding + self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
    CGFloat totalDatesBarWidth = self.dateBarContainerView.bounds.size.width - totalPaddingWidth;
    CGFloat weekdayLabelWidth = round(totalDatesBarWidth / timeIntervalPart.dateValues.count);
    CGFloat weekdayLabelHeight = descriptor.weekdaysBarHeight;
    
    CGFloat weekdayLabelOriginX = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding;
    CGFloat weekdayLabelOriginY = 0.0;
    UILabel *previousWeekdayLabel = nil;
    
    BOOL isFirstHorizontalConstraint = YES;
    BOOL isLastHorizontalConstraint = NO;
    
    NSMutableArray *weekdayLabels = [NSMutableArray new];
    
    for (NSString *weekday in timeIntervalPart.weekdays) {
        isLastHorizontalConstraint = (weekday == timeIntervalPart.weekdays.lastObject);
        
        UILabel *weekdayLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        weekdayLabel.translatesAutoresizingMaskIntoConstraints = NO;
        weekdayLabel.text = weekday;
        weekdayLabel.textColor = descriptor.dateValuesColor;
        weekdayLabel.font = descriptor.dateValuesFont;
        weekdayLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.dateBarContainerView addSubview:weekdayLabel];
        [weekdayLabels addObject:weekdayLabel];
        
        if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
            if (previousWeekdayLabel) {
                if (isFirstHorizontalConstraint) [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousWeekdayLabel(==weekdayLabel)]-0-[weekdayLabel(==previousWeekdayLabel)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousWeekdayLabel,weekdayLabel)]];
                else if (isLastHorizontalConstraint) [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousWeekdayLabel(==weekdayLabel)]-0-[weekdayLabel(==previousWeekdayLabel)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousWeekdayLabel,weekdayLabel)]];
                else [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousWeekdayLabel(==weekdayLabel)]-0-[weekdayLabel(==previousWeekdayLabel)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousWeekdayLabel,weekdayLabel)]];
                isFirstHorizontalConstraint = NO;
            }
            [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%lf-[weekdayLabel(%lf)]",weekdayLabelOriginY,weekdayLabelHeight] options:0 metrics:nil views:NSDictionaryOfVariableBindings(weekdayLabel)]];
        } else {
            if (previousWeekdayLabel) {
                if (isFirstHorizontalConstraint) [self.dateBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousWeekdayLabel(==weekdayLabel)]-0-[weekdayLabel(==previousWeekdayLabel)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousWeekdayLabel,weekdayLabel)]];
                else if (isLastHorizontalConstraint) [self.dateBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousWeekdayLabel(==weekdayLabel)]-0-[weekdayLabel(==previousWeekdayLabel)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousWeekdayLabel,weekdayLabel)]];
                else [self.dateBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousWeekdayLabel(==weekdayLabel)]-0-[weekdayLabel(==previousWeekdayLabel)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousWeekdayLabel,weekdayLabel)]];
                isFirstHorizontalConstraint = NO;
            }
            [self.dateBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%lf-[weekdayLabel(%lf)]",weekdayLabelOriginY,weekdayLabelHeight] options:0 metrics:nil views:NSDictionaryOfVariableBindings(weekdayLabel)]];
        }
        
        previousWeekdayLabel = weekdayLabel;
        weekdayLabelOriginX += weekdayLabelWidth;
    }
    
    self.weekdayLabels = weekdayLabels;
}

- (void)setupCurrentDateWithDescriptor:(GraphDateBarDescriptor*)descriptor timeIntervalPart:(GraphTimeIntervalPart*)timeIntervalPart {
    if (timeIntervalPart.currentDateValueIndex != -1 && self.graphTimeIntervalPart.dateValues.count) {
        self.todaySelectionView.hidden = NO;
        
        CGFloat totalPaddingWidth = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding + self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
        CGFloat totalDatesBarWidth = self.dateBarContainerView.bounds.size.width - totalPaddingWidth;
        
        self.todaySelectionViewXLayoutConstraint.constant = round(totalDatesBarWidth / self.graphTimeIntervalPart.dateValues.count * (timeIntervalPart.currentDateValueIndex + 0.5) + self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding - self.graphDescriptor.displayAreaDescriptor.todaySelectionWidth / 2.0);
        self.todaySelectionViewYLayoutConstraint.constant = - self.graphDescriptor.titleAreaDescriptor.titleAreaHeight;
    } else {
        self.todaySelectionView.hidden = YES;
    }
}

- (UIImage*)iconImageForIconImageIndex:(id)iconImageIndex {
    UIImage *image = [UIImage imageNamed:@"na_small_white"];
    if (iconImageIndex != [NSNull null]) image = [Utils smallWhiteWeatherImageFromCode:(NSNumber*)iconImageIndex];
    return [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:image.imageOrientation];
}

@end
