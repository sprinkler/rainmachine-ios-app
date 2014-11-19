//
//  GeocodingAddress.h
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GeocodingAddress : NSObject

@property (nonatomic, strong) NSString *route;
@property (nonatomic, strong) NSString *neighborhood;
@property (nonatomic, strong) NSString *locality;
@property (nonatomic, strong) NSString *administrativeAreaLevel1;
@property (nonatomic, strong) NSString *administrativeAreaLevel2;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *postalCode;

@property (nonatomic, readonly) NSString *closestMatchingAddressComponent;

+ (instancetype)geocodingAddressWithDictionary:(NSDictionary*)dictionary;
- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
- (void)setupWithDictionary:(NSDictionary*)dictionary;

@end
