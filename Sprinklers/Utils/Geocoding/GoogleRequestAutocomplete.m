//
//  GoogleRequestAutocomplete.m
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GoogleRequestAutocomplete.h"
#import "GoogleAutocompletePrediction.h"
#import "Constants.h"

@implementation GoogleRequestAutocomplete
+ (instancetype)autocompleteRequestWithInputString:(NSString*)inputString {
    return [[self alloc] initWithInputString:inputString];
}

- (instancetype)initWithInputString:(NSString*)inputString {
    self = [super initWithParameters:[NSDictionary dictionaryWithObjectsAndKeys:inputString,@"input",nil]];
    if (!self) return nil;
    
    _inputString = inputString;
    
    return self;
}

- (NSString*)googleRequestBaseURL {
    return @"https://maps.googleapis.com/maps/api/place/autocomplete";
}

- (NSString*)googleAPIKey {
    return kGooglePlacesAPIServerKey;
}

- (id)resultFromDictionary:(NSDictionary*)dictionary {
    NSArray *predictions = [dictionary valueForKey:@"predictions"];
    if (!predictions.count) return nil;
    
    NSMutableArray *predictionsArray = [NSMutableArray new];
    for (NSDictionary *dictionary in predictions) {
        [predictionsArray addObject:[GoogleAutocompletePrediction autocompletePredictionWithDictionary:dictionary]];
    }
    
    return predictionsArray;
}

@end
