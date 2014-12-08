//
//  UpdateStartInfo.h
//  Sprinklers
//
//  Created by Fabian Matyas on 30/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UpdateStartInfo : NSObject

@property (nonatomic, strong) NSNumber *statusCode;
@property (nonatomic, strong) NSString *message;

@end
