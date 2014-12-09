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
#import "Additions.h"

#pragma mark -

@interface GraphCell ()

- (void)setup;
- (void)setupVisualAppearanceWithDescriptor:(GraphVisualAppearanceDescriptor*)descriptor;
- (void)setupTitleAreaWithDescriptor:(GraphTitleAreaDescriptor*)descriptor;
- (void)setupIconImagesWithDescriptor:(GraphIconsBarDescriptor*)descriptor;

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
}

- (void)setupVisualAppearanceWithDescriptor:(GraphVisualAppearanceDescriptor*)descriptor {
    self.graphView.backgroundColor = descriptor.backgroundColor;
    if (descriptor.cornerRadius > 0.0) self.graphView.layer.cornerRadius = descriptor.cornerRadius;
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
        iconImageView.frame = CGRectMake(iconImageViewOriginX, 0.0, iconImageViewWidth, iconImageViewHeight);
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

@end
