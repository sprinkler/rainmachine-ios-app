//
//  Constants.h
//  Sprinklers
//
//  Created by Razvan Irimia on 1/24/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#ifndef Sprinklers_Constants_h
#define Sprinklers_Constants_h

#define broadcastPort   15800
#define listenPort      15900

#define listenTimeout   10.0
#define refreshTimeout  20.0

#define resendTimeout   1.0
#define keepAliveTime   0.05

#define burstBroadcasts 3
#define keepAliveTo     50

#define messageDelimiter    @"||"
#define keepAliveURL        @"www.sprinklers.ro"
#define keepAlivePort       16000
#define keepAliveTimeout    0

#endif
