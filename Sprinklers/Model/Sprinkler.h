//
//  Sprinkler.h
//  Sprinklers
//
//  Created by Fabian Matyas on 11/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Sprinkler : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * isLocalDevice;
@property (nonatomic, retain) NSString * lastError;
@property (nonatomic, retain) NSDate * lastSprinklerVersionRequest;
@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSNumber * loginRememberMe;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * port;

@end
