//
//  UpdateInfo.h
//  Sprinklers
//
//  Created by Fabian Matyas on 30/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UpdateInfo4PackageDetails : NSObject

@property (nonatomic, strong) NSString *packageName;
@property (nonatomic, strong) NSString *theNewVersion;
@property (nonatomic, strong) NSString *oldVersion;

+ (UpdateInfo4PackageDetails *)createFromJson:(NSDictionary *)jsonObj;

@end
