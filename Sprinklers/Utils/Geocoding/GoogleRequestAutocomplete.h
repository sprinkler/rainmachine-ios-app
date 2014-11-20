//
//  GoogleRequestAutocomplete.h
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GoogleRequest.h"

@interface GoogleRequestAutocomplete : GoogleRequest

@property (nonatomic, strong) NSString *inputString;

+ (instancetype)autocompleteRequestWithInputString:(NSString*)inputString;
- (instancetype)initWithInputString:(NSString*)inputString;

@end
