//
//  GoogleAutocompletePrediction.h
//  Sprinklers
//
//  Created by Istvan Sipos on 19/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GoogleAutocompletePrediction : NSObject

@property (nonatomic, strong) NSString *placeDescription;
@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *placeId;
@property (nonatomic, strong) NSArray *matchedRanges;

+ (instancetype)autocompletePredictionWithDictionary:(NSDictionary*)dictionary;
- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
- (void)setupWithDictionary:(NSDictionary*)dictionary;

@end
