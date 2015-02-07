//
//  GraphDataFormatter.h
//  Sprinklers
//
//  Created by Istvan Sipos on 07/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    GraphDataFormatterFieldTypeString,
    GraphDataFormatterFieldTypeNumber,
    GraphDataFormatterFieldTypeDate,
    GraphDataFormatterFieldTypeTime
} GraphDataFormatterFieldType;

extern NSString *GraphDataFormatterDescriptorFieldType;
extern NSString *GraphDataFormatterDescriptorFieldKey;
extern NSString *GraphDataFormatterDescriptorFieldValue;
extern NSString *GraphDataFormatterDescriptorFieldAlignment;
extern NSString *GraphDataFormatterDescriptorFieldColor;
extern NSString *GraphDataFormatterDescriptorFieldFont;

@class GraphDataSource;

@interface GraphDataFormatter : NSObject

@property (nonatomic, strong) NSString *formatterKey;
@property (nonatomic, strong) NSArray *descriptors;
@property (nonatomic, strong) NSArray *graphDataSourceValues;
@property (nonatomic, strong) NSArray *subFormatters;
@property (nonatomic, assign) NSInteger subFormatterIndex;

- (void)registerFormatterCellsInTableView:(UITableView*)tableView;
- (NSInteger)numberOfSection;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;
- (CGFloat)heighForRowAtIndexPath:(NSIndexPath*)indexPath;
- (UITableViewCell*)cellForRowAtIndexPath:(NSIndexPath*)indexPath inTableView:(UITableView*)tableView;

@end
