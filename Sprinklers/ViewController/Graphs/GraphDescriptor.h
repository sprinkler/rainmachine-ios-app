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

@interface GraphDescriptor : NSObject

@property (nonatomic, strong) NSString *graphIdentifier;
@property (nonatomic, strong) GraphTimeInterval *graphTimeInterval;
@property (nonatomic, strong) GraphVisualAppearanceDescriptor *visualAppearanceDescriptor;
@property (nonatomic, strong) GraphTitleAreaDescriptor *titleAreaDescriptor;
@property (nonatomic, strong) GraphIconsBarDescriptor *iconsBarDescriptor;
@property (nonatomic, strong) GraphValuesBarDescriptor *valuesBarDescriptor;

+ (GraphDescriptor*)defaultDescriptor;

@end
