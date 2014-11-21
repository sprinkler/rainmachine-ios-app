//
//  ProvisionLocation.h
//  Sprinklers
//
//  Created by Istvan Sipos on 21/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProvisionLocation : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, assign) double elevation;
@property (nonatomic, strong) NSString *timezone;
@property (nonatomic, assign) double rainSensitivity;
@property (nonatomic, assign) int wsDays;
@property (nonatomic, strong) NSString *stationID;
@property (nonatomic, strong) NSString *stationName;
@property (nonatomic, assign) BOOL stationDownloaded;
@property (nonatomic, strong) NSString *stationSource;
@property (nonatomic, assign) BOOL doyDownloaded;
@property (nonatomic, assign) double et0Average;

+ (ProvisionLocation*)createFromJson:(NSDictionary*)jsonObj;

@end
