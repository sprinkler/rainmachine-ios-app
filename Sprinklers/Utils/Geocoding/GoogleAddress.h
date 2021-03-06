//
//  GoogleAddress.h
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GoogleAddress : NSObject

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) NSString *premise;
@property (nonatomic, strong) NSString *streetNumber;
@property (nonatomic, strong) NSString *route;
@property (nonatomic, strong) NSString *neighborhood;
@property (nonatomic, strong) NSString *locality;
@property (nonatomic, strong) NSString *administrativeAreaLevel1;
@property (nonatomic, strong) NSString *administrativeAreaLevel1Short;
@property (nonatomic, strong) NSString *administrativeAreaLevel2;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *countryShort;
@property (nonatomic, strong) NSString *postalCode;

+ (instancetype)googleAddressWithDictionary:(NSDictionary*)dictionary;
- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
- (void)setupWithDictionary:(NSDictionary*)dictionary;

@end
