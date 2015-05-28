//
//  ServiceManager.h
//  Sprinklers
//
//  Created by Razvan Irimia on 1/24/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkUtilities.h"
#import "GCDAsyncUdpSocket.h"
#import "DiscoveredSprinklers.h"
#import "Sprinkler.h"
#import "Additions.h"
#import "Constants.h"
         
@interface ServiceManager : NSObject <GCDAsyncUdpSocketDelegate> {
    
    GCDAsyncUdpSocket *broadcastUdpSocket;
    GCDAsyncUdpSocket *receiveUdpSocket;
    GCDAsyncUdpSocket *keepAliveSocket;
    
    NSTimer *sockTimeOutTimer;
    NSTimer *autoRefreshTimer;
    NSTimer *reSendTimer;
    NSTimer *keepAliveTimer;
    
    NSString *localIpAddress;
    NSString *localNetmask;
    NSString *broadcastAddress;
    NSData *broadcastMessage;
}

- (BOOL)startBroadcastForSprinklers:(BOOL)silent;
- (BOOL)sendBroadcast:(BOOL)silent;
- (BOOL)stopBroadcast;

- (NSMutableArray *)getDiscoveredSprinklersWithAPFlag:(NSNumber*)apFlag;
- (void)clearDiscoveredSprinklers;

+ (id)current;

@end
