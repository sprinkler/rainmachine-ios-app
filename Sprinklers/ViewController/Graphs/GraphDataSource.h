//
//  GraphDataSource.h
//  Sprinklers
//
//  Created by Istvan Sipos on 26/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerProxy.h"

@interface GraphDataSource : NSObject <SprinklerResponseProtocol>

@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSArray *iconImages;
@property (nonatomic, strong) ServerProxy *serverProxy;
@property (nonatomic, strong) NSError *error;

+ (GraphDataSource*)defaultDataSource;
- (void)startLoading;
- (NSArray*)valuesFromLoadedData:(id)data;

@end
