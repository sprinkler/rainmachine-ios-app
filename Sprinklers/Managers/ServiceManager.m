//
//  ServiceManager.m
//  Sprinklers
//
//  Created by Razvan Irimia on 1/24/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "ServiceManager.h"

static ServiceManager *current = nil;

@interface ServiceManager () {
}

@property (strong, nonatomic) NSMutableArray *discoveredSprinklers;

@end

@implementation ServiceManager

#pragma mark - Singleton

+ (id)current {
	@synchronized(self) {
		if (current == nil)
			current = [[super allocWithZone:NULL] init];
	}
	return current;
}

#pragma mark - Methods

- (BOOL)startBroadcastForSprinklers:(BOOL)silent {
    
    self.discoveredSprinklers = [NSMutableArray array];

    localIpAddress = [NetworkUtilities ipAddressForWifi];
    localNetmask = [NetworkUtilities netmaskForWifi];
    
    if ([NSString isEmpty:localIpAddress] || [NSString isEmpty:localNetmask]) {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Sprinklers autodiscovery cannot open WiFi interface!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //[alert show];
        NSLog(@"Sprinklers autodiscovery cannot open WiFi interface!");
        return NO;
    }
    
    broadcastAddress = [NetworkUtilities broadcastAddressForAddress:localIpAddress withMask:localNetmask];
    broadcastMessage = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
    
    if (broadcastAddress == nil || broadcastMessage == nil) {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Sprinklers autodiscovery cannot read broadcast params!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //[alert show];
        NSLog(@"Sprinklers autodiscovery cannot read broadcast params!");
        return NO;
    }
    
    broadcastUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [broadcastUdpSocket enableBroadcast:YES error:nil];
    
    if (broadcastUdpSocket == nil) {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Sprinklers autodiscovery cannot initialize broadcast socket!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //[alert show];
        NSLog(@"Sprinklers autodiscovery cannot initialize broadcast socket!");
        return NO;
    }
    
    keepAliveSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    if (keepAliveSocket == nil) {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Sprinklers autodiscovery cannot keep alive socket!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //[alert show];
        NSLog(@"Sprinklers autodiscovery cannot keep alive socket!");
        return NO;
    }
    
    if ([self sendBroadcast:silent]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)sendBroadcast:(BOOL)silent {
    
    [self stopBroadcast];
    
    receiveUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *udpError;

    if (receiveUdpSocket == nil) {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Sprinklers autodiscovery cannot initialize discovery socket!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //[alert show];
        NSLog(@"Sprinklers autodiscovery cannot initialize discovery socket!");
        return NO;
    }
    
    if (![receiveUdpSocket bindToPort:listenPort error:&udpError]) {
        bool socketBound = NO;
        for(int i = 0; i < burstBroadcasts; i++) {
            if ([receiveUdpSocket bindToPort:listenPort error:&udpError]) {
                [NSThread sleepForTimeInterval:1];
                socketBound = YES;
                break;
            }
        }
        if (!socketBound) {
            //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Sprinklers autodiscovery cannot bind to discovery port!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            //[alert show];
            NSLog(@"Sprinklers autodiscovery cannot bind to discovery port!");
            return NO;
        }
    }
    
    if (![receiveUdpSocket beginReceiving:&udpError]) {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Sprinklers autodiscovery cannot receive on discovery port!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //[alert show];
        NSLog(@"Sprinklers autodiscovery cannot bind to discovery port!");
        return NO;
    }
    
    for (int i = 0; i < burstBroadcasts; i++) {
        NSLog(@"Sending broadcast...");
        [broadcastUdpSocket sendData:broadcastMessage toHost:broadcastAddress port:broadcastPort withTimeout:-1 tag:0];
    }
    
    if (!silent) {
        reSendTimer = [NSTimer scheduledTimerWithTimeInterval:resendTimeout target:self selector:@selector(resendBroadcast) userInfo:nil repeats:NO];
        keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:resendTimeout target:self selector:@selector(keepAlive) userInfo:nil repeats:NO];
    }
    
    return YES;
}

- (BOOL)stopBroadcast {
    [receiveUdpSocket close];
    [autoRefreshTimer invalidate];
    [reSendTimer invalidate];
    [keepAliveTimer invalidate];
    [sockTimeOutTimer invalidate];
    return YES;
}

- (void)resendBroadcast {
    for (int i = 0; i < burstBroadcasts; i++) {
       [broadcastUdpSocket sendData:broadcastMessage toHost:broadcastAddress port:broadcastPort withTimeout:-1 tag:0];
    }
        
    reSendTimer = [NSTimer scheduledTimerWithTimeInterval:resendTimeout target:self selector:@selector(resendBroadcast) userInfo:nil repeats:NO];
}

- (void)keepAlive {
    if ([sockTimeOutTimer isValid]) {
        [keepAliveSocket sendData:broadcastMessage toHost:keepAliveURL port:keepAlivePort withTimeout:0 tag:0];
        keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:resendTimeout target:self selector:@selector(keepAlive) userInfo:nil repeats:NO];
    }
}

- (void)updateSprinklers {
    NSMutableArray *updatedSprinklers = [NSMutableArray array];
    for (DiscoveredSprinklers *ds in self.discoveredSprinklers) {
        if ([ds.updated timeIntervalSinceNow] <= 0 && [ds.updated timeIntervalSinceNow] > -(refreshTimeout + listenTimeout)) {
            [updatedSprinklers addObject:ds];
        }
    }
    self.discoveredSprinklers = [NSMutableArray arrayWithArray:updatedSprinklers];
}

- (NSMutableArray *)getDiscoveredSprinklersWithAPFlag:(NSNumber*)apFlag {
    NSMutableArray *filteredDiscoveredSprinklers = [NSMutableArray array];
    for (DiscoveredSprinklers *sprinkler in self.discoveredSprinklers) {
        BOOL add = NO;
        if (apFlag) {
            if ([apFlag boolValue]) {
                // Return only the fully setup sprinklers: API3 sprinklers || API4 with apFlag=1
                add = !(sprinkler.apFlag) || (![sprinkler.apFlag isEqualToString:@"0"]);
            } else {
                add = [sprinkler.apFlag isEqualToString:@"0"];
            }
        } else {
            // apFlag is nil, add everything
            add = YES;
        }
        
        if (add) {
            [filteredDiscoveredSprinklers addObject:sprinkler];
        }
    }
    
    return filteredDiscoveredSprinklers;
}

#pragma mark - GCGAsyncUdpSocket delegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *host = nil;
    uint16_t port = 0;
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
    
    // Overwrite port value. For the discovered sprinklers we will set a default port
    port = 443;
    
//    DLog(@"discovery string: %@", string);
    
    NSArray *splits = [string componentsSeparatedByString:messageDelimiter];
    if (splits.count >= 5) {
        // Sprinkler2
        NSURL *baseURL = [NSURL URLWithString:splits[3]];
        port = [[baseURL port] integerValue];
    }
    
    //NSLog(@"UDP message received from sprinkler: %@, %@:%d", string, host, port);
    
    if (splits && splits.count >= 4 && [splits[0] isEqualToString:@"SPRINKLER"]) {
        NSString *sprinklerId = splits[1];
        
        BOOL found = NO;
        for (DiscoveredSprinklers *ds in self.discoveredSprinklers) {
            if ([ds.sprinklerId isEqualToString:sprinklerId]) {
                ds.updated = [NSDate date];
                found = YES;
                break;
            }
        }
        
        if (!found) {
            DiscoveredSprinklers *sprinkler = [[DiscoveredSprinklers alloc] init];
            sprinkler.sprinklerId = splits[1];
            sprinkler.sprinklerName = splits[2];
            sprinkler.url = splits[3];
            sprinkler.updated = [NSDate date];
            sprinkler.host = host;
            sprinkler.port = port;
            sprinkler.apFlag = splits.count >= 5 ? splits[4] : nil;
            // Keep apFlag's value only if it is 0 or 1. This way we filter out possible garbage values received from SPK1
            sprinkler.apFlag = (([sprinkler.apFlag isEqualToString:@"0"]) || ([sprinkler.apFlag isEqualToString:@"1"])) ? sprinkler.apFlag : nil;
            
            [self.discoveredSprinklers addObject:sprinkler];
        }
    }
    
    [self updateSprinklers];
}

@end
