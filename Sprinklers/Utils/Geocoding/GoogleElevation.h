//
//  GoogleElevation.h
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GoogleElevation : NSObject

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) NSString *elevation;

+ (instancetype)elevationWithDictionary:(NSDictionary*)dictionary;
- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
- (void)setupWithDictionary:(NSDictionary*)dictionary;

@end
