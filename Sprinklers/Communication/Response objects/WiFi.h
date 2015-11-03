//
//  WiFi.h
//  Sprinklers
//
//  Created by Fabian Matyas on 01/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WiFi : NSObject

@property (nonatomic, strong) NSNumber *isEncrypted;
@property (nonatomic, strong) NSString *SSID;
@property (nonatomic, strong) NSNumber *isWPA2;
@property (nonatomic, strong) NSNumber *isWPA;
@property (nonatomic, strong) NSString *signal;
@property (nonatomic, strong) NSNumber *isWEP;
@property (nonatomic, strong) NSString *channel;
@property (nonatomic, strong) NSString *BSS;

@end
