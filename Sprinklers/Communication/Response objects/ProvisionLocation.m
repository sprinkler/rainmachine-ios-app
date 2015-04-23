//
//  ProvisionLocation.m
//  Sprinklers
//
//  Created by Istvan Sipos on 21/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProvisionLocation.h"
#import "Additions.h"

@implementation ProvisionLocation

+ (ProvisionLocation*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        ProvisionLocation *location = [[ProvisionLocation alloc] init];
        
        location.name = [jsonObj nullProofedStringValueForKey:@"name"];
        location.latitude = [jsonObj nullProofedDoubleValueForKey:@"latitude"];
        location.longitude = [jsonObj nullProofedDoubleValueForKey:@"longitude"];
        location.address = [jsonObj nullProofedStringValueForKey:@"address"];
        location.state = [jsonObj nullProofedStringValueForKey:@"state"];
        location.zip = [jsonObj nullProofedStringValueForKey:@"zip"];
        location.elevation = [jsonObj nullProofedDoubleValueForKey:@"elevation"];
        location.timezone = [jsonObj nullProofedStringValueForKey:@"timezone"];
        location.rainSensitivity = [jsonObj nullProofedDoubleValueForKey:@"rainSensitivity"];
        location.windSensitivity = [jsonObj nullProofedDoubleValueForKey:@"windSensitivity"];
        location.wsDays = [jsonObj nullProofedIntValueForKey:@"wsDays"];
        location.stationID = [jsonObj nullProofedStringValueForKey:@"stationID"];
        location.stationName = [jsonObj nullProofedStringValueForKey:@"stationName"];
        location.stationDownloaded = [jsonObj nullProofedBoolValueForKey:@"stationDownloaded"];
        location.stationSource = [jsonObj nullProofedStringValueForKey:@"stationSource"];
        location.doyDownloaded = [jsonObj nullProofedBoolValueForKey:@"doyDownloaded"];
        location.et0Average = [jsonObj nullProofedDoubleValueForKey:@"et0Average"];
        
        return location;
    }
    return nil;
}

@end
