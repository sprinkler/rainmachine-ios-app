//
//  ServerResponseStartStopProgram.h
//  Sprinklers
//
//  Created by Fabian Matyas on 19/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StartStopProgramResponse : NSObject

@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *state;

@end
