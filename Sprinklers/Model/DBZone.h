//
//  DBZone.h
//  Sprinklers
//
//  Created by Fabian Matyas on 18/04/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Sprinkler;

@interface DBZone : NSManagedObject

@property (nonatomic, retain) NSNumber * counter;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) Sprinkler *sprinkler;

@end
