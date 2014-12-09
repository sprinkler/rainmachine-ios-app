//
//  GraphCell.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphCell.h"
#import "GraphDescriptor.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphTitleAreaDescriptor.h"
#import "GraphIconsBarDescriptor.h"
#import "GraphValuesBarDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"
#import "Additions.h"

#pragma mark -

@interface GraphCell ()

- (void)setup;
- (void)setupVisualAppearanceWithDescriptor:(GraphVisualAppearanceDescriptor*)descriptor;
- (void)setupTitleAreaWithDescriptor:(GraphTitleAreaDescriptor*)descriptor;
- (void)setupIconImagesWithDescriptor:(GraphIconsBarDescriptor*)descriptor;
- (void)setupValuesWithDescriptor:(GraphValuesBarDescriptor*)descriptor;
- (void)setupDisplayAreaWithDescriptor:(GraphDisplayAreaDescriptor*)descriptor;

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

#pragma mark - Helper methods

- (void)setup {
    [self setupVisualAppearanceWithDescriptor:self.graphDescriptor.visualAppearanceDescriptor];
    [self setupTitleAreaWithDescriptor:self.graphDescriptor.titleAreaDescriptor];
    [self setupIconImagesWithDescriptor:self.graphDescriptor.iconsBarDescriptor];
    [self setupValuesWithDescriptor:self.graphDescriptor.valuesBarDescriptor];
    [self setupDisplayAreaWithDescriptor:self.graphDescriptor.displayAreaDescriptor];
}

- (void)setupVisualAppearanceWithDescriptor:(GraphVisualAppearanceDescriptor*)descriptor {
    self.graphContainerView.backgroundColor = descriptor.backgroundColor;
    if (descriptor.cornerRadius > 0.0) self.graphContainerView.layer.cornerRadius = descriptor.cornerRadius;
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

- (void)setupIconImagesWithDescriptor:(GraphIconsBarDescriptor*)descriptor {
    if (!descriptor) {
        self.iconsBarContainerViewHeightLayoutConstraint.constant = 0.0;
        return;
    }
    
    self.iconsBarContainerViewHeightLayoutConstraint.constant = descriptor.iconsBarHeight;
    
    CGFloat totalPaddingWidth = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding + self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
    CGFloat totalIconBarWidth = self.iconsBarContainerView.bounds.size.width - totalPaddingWidth;
    CGFloat iconImageViewWidth = round(totalIconBarWidth / descriptor.iconImages.count);
    CGFloat iconImageViewHeight = descriptor.iconsHeight;
    CGFloat remainingTrailingWidth = totalIconBarWidth - iconImageViewWidth * descriptor.iconImages.count;
    
    CGFloat iconImageViewOriginX = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding;
    CGFloat iconImageViewOriginY = ceil((descriptor.iconsBarHeight - descriptor.iconsHeight) / 2.0);
    UIImageView *previousIconImageView = nil;
    
    BOOL isFirstHorizontalConstraint = YES;
    BOOL isLastHorizontalConstraint = NO;
    
    for (UIImage *iconImage in descriptor.iconImages) {
        isLastHorizontalConstraint = (iconImage == descriptor.iconImages.lastObject);
        
        UIImageView *iconImageView = [[UIImageView alloc] initWithImage:[iconImage imageByFillingWithColor:descriptor.iconImagesColor]];
        iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
        iconImageView.frame = CGRectMake(iconImageViewOriginX, iconImageViewOriginY, iconImageViewWidth, iconImageViewHeight);
        iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.iconsBarContainerView addSubview:iconImageView];
        
        if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
            if (previousIconImageView) {
                if (isFirstHorizontalConstraint) [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousIconImageView(==iconImageView)]-[iconImageView(==previousIconImageView)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousIconImageView,iconImageView)]];
                else if (isLastHorizontalConstraint) [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousIconImageView(==iconImageView)]-[iconImageView(==previousIconImageView)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding + remainingTrailingWidth] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousIconImageView,iconImageView)]];
                else [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousIconImageView(==iconImageView)]-[iconImageView(==previousIconImageView)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousIconImageView,iconImageView)]];
                isFirstHorizontalConstraint = NO;
            }
            [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%lf-[iconImageView(%lf)]",iconImageViewOriginY,iconImageViewHeight] options:0 metrics:nil views:NSDictionaryOfVariableBindings(iconImageView)]];
        } else {
            if (previousIconImageView) {
                if (isFirstHorizontalConstraint) [self.iconsBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousIconImageView(==iconImageView)]-[iconImageView(==previousIconImageView)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousIconImageView,iconImageView)]];
                else if (isLastHorizontalConstraint) [self.iconsBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousIconImageView(==iconImageView)]-[iconImageView(==previousIconImageView)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding + remainingTrailingWidth] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousIconImageView,iconImageView)]];
                else [self.iconsBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousIconImageView(==iconImageView)]-[iconImageView(==previousIconImageView)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousIconImageView,iconImageView)]];
                isFirstHorizontalConstraint = NO;
            }
            [self.iconsBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%lf-[iconImageView(%lf)]",iconImageViewOriginY,iconImageViewHeight] options:0 metrics:nil views:NSDictionaryOfVariableBindings(iconImageView)]];
        }
        
        previousIconImageView = iconImageView;
        iconImageViewOriginX += iconImageViewWidth;
    }
}

- (void)setupValuesWithDescriptor:(GraphValuesBarDescriptor*)descriptor {
    if (!descriptor) {
        self.valuesBarContainerViewHeightLayoutConstraint.constant = 0.0;
        return;
    }
    
    self.valuesBarContainerViewHeightLayoutConstraint.constant = descriptor.valuesBarHeight;
    
    CGFloat totalPaddingWidth = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding + self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
    CGFloat totalValuesBarWidth = self.valuesBarContainerView.bounds.size.width - totalPaddingWidth;
    CGFloat valueLabelWidth = round(totalValuesBarWidth / descriptor.values.count);
    CGFloat valueLabelHeight = descriptor.valuesBarHeight;
    CGFloat remainingTrailingWidth = totalValuesBarWidth - valueLabelWidth * descriptor.values.count;
    
    CGFloat valueLabelOriginX = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding;
    CGFloat valueLabelOriginY = 0.0;
    UILabel *previousValueLabel = nil;
    
    BOOL isFirstHorizontalConstraint = YES;
    BOOL isLastHorizontalConstraint = NO;
    
    for (NSNumber *value in descriptor.values) {
        isLastHorizontalConstraint = (value == descriptor.values.lastObject);
        
        UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(valueLabelOriginX, valueLabelOriginY, valueLabelWidth, valueLabelHeight)];
        valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        valueLabel.text = [NSString stringWithFormat:@"%d",value.intValue];
        valueLabel.textColor = descriptor.valuesColor;
        valueLabel.font = descriptor.valuesFont;
        valueLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.valuesBarContainerView addSubview:valueLabel];
        
        if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
            if (previousValueLabel) {
                if (isFirstHorizontalConstraint) [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousValueLabel(==valueLabel)]-[valueLabel(==previousValueLabel)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousValueLabel,valueLabel)]];
                else if (isLastHorizontalConstraint) [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousValueLabel(==valueLabel)]-[valueLabel(==previousValueLabel)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding + remainingTrailingWidth] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousValueLabel,valueLabel)]];
                else [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousValueLabel(==valueLabel)]-[valueLabel(==previousValueLabel)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousValueLabel,valueLabel)]];
                isFirstHorizontalConstraint = NO;
            }
            [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%lf-[valueLabel(%lf)]",valueLabelOriginY,valueLabelHeight] options:0 metrics:nil views:NSDictionaryOfVariableBindings(valueLabel)]];
        } else {
            if (previousValueLabel) {
                if (isFirstHorizontalConstraint) [self.valuesBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[previousValueLabel(==valueLabel)]-[valueLabel(==previousValueLabel)]", self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousValueLabel,valueLabel)]];
                else if (isLastHorizontalConstraint) [self.iconsBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[previousValueLabel(==valueLabel)]-[valueLabel(==previousValueLabel)]-%lf-|", self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding + remainingTrailingWidth] options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousValueLabel,valueLabel)]];
                else [self.iconsBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousValueLabel(==valueLabel)]-[valueLabel(==previousValueLabel)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previousValueLabel,valueLabel)]];
                isFirstHorizontalConstraint = NO;
            }
            [self.valuesBarContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%lf-[valueLabel(%lf)]",valueLabelOriginY,valueLabelHeight] options:0 metrics:nil views:NSDictionaryOfVariableBindings(valueLabel)]];
        }
        
        previousValueLabel = valueLabel;
        valueLabelOriginX += valueLabelWidth;
    }
    
    self.valuesUnitsLabel.text = descriptor.units;
    self.valuesUnitsLabel.textColor = descriptor.unitsColor;
    self.valuesUnitsLabel.font = descriptor.unitsFont;
    self.valuesUnitsLabelWidthLayoutConstraint.constant = self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
}

- (void)setupDisplayAreaWithDescriptor:(GraphDisplayAreaDescriptor*)descriptor {
    self.graphViewHeightLayoutConstraint.constant = descriptor.displayAreaHeight;
}

@end
