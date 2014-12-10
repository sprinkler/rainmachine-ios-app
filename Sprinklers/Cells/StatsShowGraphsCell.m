//
//  StatsShowGraphsCell.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "StatsShowGraphsCell.h"

#pragma mark -

@interface StatsShowGraphsCell ()

- (void)setup;

@end

#pragma mark -

@implementation StatsShowGraphsCell

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;
    
    [self addObserver:self forKeyPath:@"graphsTimeInterval" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)awakeFromNib {
    self.backgroundColor = [UIColor colorWithWhite:0.89 alpha:1.0];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"graphsTimeInterval"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    [self setup];
}

- (void)setup {
    self.graphsTimeIntervalLabel.text = [NSString stringWithFormat:@"1 %@",self.graphsTimeInterval.name];
}

@end
