//
//  API4ErrorResponse.h
//  Sprinklers
//
//  Created by Fabian Matyas on 26/08/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface API4StatusResponse : NSObject

@property (nonatomic, strong) NSNumber *statusCode;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSDictionary *program; // Returned by Create Program

@end
