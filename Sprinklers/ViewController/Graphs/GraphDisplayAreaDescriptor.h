//
//  GraphDisplayAreaDescriptor.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GraphDisplayAreaDescriptor : NSObject

@property (nonatomic, assign) CGFloat displayAreaHeight;

+ (GraphDisplayAreaDescriptor*)defaultDescriptor;

@end
