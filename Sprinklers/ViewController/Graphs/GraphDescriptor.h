//
//  GraphDescriptor.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GraphTimeInterval;
@class GraphVisualAppearanceDescriptor;
@class GraphTitleAreaDescriptor;
@class GraphIconsBarDescriptor;
@class GraphValuesBarDescriptor;
@class GraphDisplayAreaDescriptor;
@class GraphDateBarDescriptor;

@interface GraphDescriptor : NSObject

@property (nonatomic, strong) NSString *graphIdentifier;
@property (nonatomic, strong) GraphTimeInterval *graphTimeInterval;
@property (nonatomic, strong) GraphVisualAppearanceDescriptor *visualAppearanceDescriptor;
@property (nonatomic, strong) GraphTitleAreaDescriptor *titleAreaDescriptor;
@property (nonatomic, strong) GraphIconsBarDescriptor *iconsBarDescriptor;
@property (nonatomic, strong) GraphValuesBarDescriptor *valuesBarDescriptor;
@property (nonatomic, strong) GraphDisplayAreaDescriptor *displayAreaDescriptor;
@property (nonatomic, strong) GraphDateBarDescriptor *dateBarDescriptor;

+ (GraphDescriptor*)defaultDescriptor;

@property (nonatomic, readonly) CGFloat totalGraphHeight;

@end
