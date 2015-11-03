//
//  UpdateInfo.m
//  Sprinklers
//
//  Created by Fabian Matyas on 30/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "UpdateInfo4PackageDetails.h"

@implementation UpdateInfo4PackageDetails

+ (UpdateInfo4PackageDetails *)createFromJson:(NSDictionary *)jsonObj {
    if (jsonObj) {
        UpdateInfo4PackageDetails *packageDetails = [[UpdateInfo4PackageDetails alloc] init];
        
        packageDetails.packageName = [jsonObj objectForKey:@"packageName"];
        packageDetails.theNewVersion = [jsonObj objectForKey:@"newVersion"];
        packageDetails.oldVersion = [jsonObj objectForKey:@"oldVersion"];
        
        return packageDetails;
    }
    return nil;
}

@end
