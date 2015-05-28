//
//  UpdateInfo.m
//  Sprinklers
//
//  Created by Fabian Matyas on 30/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "UpdateInfo4.h"
#import "UpdateInfo4PackageDetails.h"

@implementation UpdateInfo4

+ (UpdateInfo4 *)createFromJson:(NSDictionary *)jsonObj {
    if (jsonObj) {
        UpdateInfo4 *info = [[UpdateInfo4 alloc] init];
        
        info.updateStatus = [jsonObj objectForKey:@"updateStatus"];
        info.update = [jsonObj objectForKey:@"update"];
        info.lastUpdateCheck = [jsonObj objectForKey:@"lastUpdateCheck"];

        NSArray *packageDetails = [jsonObj valueForKey:@"packageDetails"];
        if (packageDetails && [packageDetails isKindOfClass:[NSArray class]]) {
            NSMutableArray *unpackedPackageDetails = [NSMutableArray array];
            for (id obj in packageDetails) {
                if ([obj isKindOfClass:[NSDictionary class]]) {
                    UpdateInfo4PackageDetails *details = [UpdateInfo4PackageDetails createFromJson:obj];
                    [unpackedPackageDetails addObject:details];
                }
            }
            info.packageDetails = unpackedPackageDetails;
        }

        return info;
    }
    return nil;
}

@end
