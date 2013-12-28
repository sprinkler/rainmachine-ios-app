//
//  SPServerProxy.h
//  AFNetworking iOS Example
//
//  Created by Fabian Matyas on 02/12/13.
//  Copyright (c) 2013 Gowalla. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"

@class AFHTTPRequestOperationManager;
@class ZoneProperty;
@class StartStopWatering;

@interface ServerProxy : NSObject
{
}

@property (nonatomic, weak) id<SprinklerResponseProtocol> delegate;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) NSString* serverURL;

- (id)initWithServerURL:(NSString*)serverURL delegate:(id<SprinklerResponseProtocol>)del jsonRequest:(BOOL)jsonRequest;
- (void)loginWithUserName:(NSString*)userName password:(NSString*)password rememberMe:(BOOL)rememberMe;

- (void)requestWeatherData;
- (void)requestZonePropertiesList;
- (void)requestWaterNowZoneList;
- (void)requestWaterActionsForZone:(NSNumber*)zoneId;

- (void)sendZoneProperties:(ZoneProperty*)zoneProperty;
- (void)toggleWatering:(BOOL)switchValue onZoneWithId:(NSNumber*)theId andCounter:(NSNumber*)counter;

@end