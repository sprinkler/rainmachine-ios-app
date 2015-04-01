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
@class GraphDisplayAreaDescriptor;
@class GraphDateBarDescriptor;
@class GraphDataSource;

@interface GraphDescriptor : NSObject

@property (nonatomic, strong) NSString *graphIdentifier;
@property (nonatomic, strong) GraphDataSource *dataSource;
@property (nonatomic, strong) GraphTimeInterval *graphTimeInterval;
@property (nonatomic, strong) GraphVisualAppearanceDescriptor *visualAppearanceDescriptor;
@property (nonatomic, strong) GraphTitleAreaDescriptor *titleAreaDescriptor;
@property (nonatomic, strong) NSDictionary *iconsBarDescriptorsDictionary;
@property (nonatomic, strong) NSDictionary *valuesBarDescriptorsDictionary;
@property (nonatomic, strong) GraphDisplayAreaDescriptor *displayAreaDescriptor;
@property (nonatomic, strong) GraphDateBarDescriptor *dateBarDescriptor;
@property (nonatomic, assign) BOOL canDisable;
@property (nonatomic, assign) BOOL isDisabled;

+ (GraphDescriptor*)defaultDescriptor;

@property (nonatomic, readonly) CGFloat totalGraphHeight;
@property (nonatomic, readonly) CGFloat totalGraphHeaderHeight;
@property (nonatomic, readonly) CGFloat totalGraphFooterHeight;

@end
