//
//  GoogleRequestPlaceDetails.h
//  Sprinklers
//
//  Created by Istvan Sipos on 19/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GoogleRequest.h"

@class GoogleAutocompletePrediction;

@interface GoogleRequestPlaceDetails : GoogleRequest

@property (nonatomic, strong) GoogleAutocompletePrediction *autocompletePrediction;

+ (instancetype)placeDetailsRequestWithAutocompletePrediction:(GoogleAutocompletePrediction*)autocompletePrediction;
- (instancetype)initWithAutocompletePrediction:(GoogleAutocompletePrediction*)autocompletePrediction;

@end
