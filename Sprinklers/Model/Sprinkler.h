//
//  Sprinkler.h
//  Sprinklers
//
//  Created by Fabian Matyas on 11/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Sprinkler : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * port;
@property (nonatomic, retain) NSString * lastError;
@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSNumber * loginRememberMe;

@end
