//
//  GraphCell.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphCell.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphTitleAreaDescriptor.h"
#import "GraphDescriptor.h"

#pragma mark -

@interface GraphCell ()

- (void)setup;

@end

#pragma mark -

@implementation GraphCell

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

- (void)setup {
    GraphVisualAppearanceDescriptor *visualAppearanceDescriptor = self.graphDescriptor.visualAppearanceDescriptor;
    GraphTitleAreaDescriptor *titleAreaDescriptor = self.graphDescriptor.titleAreaDescriptor;
    
    self.graphView.backgroundColor = visualAppearanceDescriptor.backgroundColor;
    if (visualAppearanceDescriptor.cornerRadius > 0.0) self.graphView.layer.cornerRadius = visualAppearanceDescriptor.cornerRadius;
    
    self.titleAreaContainerViewHeightLayoutConstraint.constant = titleAreaDescriptor.titleAreaHeight;
    self.titleAreaSeparatorView.backgroundColor = titleAreaDescriptor.titleAreaSeparatorColor;
    self.graphTitleLabel.text = titleAreaDescriptor.title;
    self.graphTitleLabel.textColor = titleAreaDescriptor.titleColor;
    self.graphTitleLabel.font = titleAreaDescriptor.titleFont;
    self.graphUnitsLabel.text = titleAreaDescriptor.units;
    self.graphUnitsLabel.textColor = titleAreaDescriptor.unitsColor;
    self.graphUnitsLabel.font = titleAreaDescriptor.unitsFont;
}

@end
