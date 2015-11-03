//
//  GraphDataSourceProgramRunTime.h
//  Sprinklers
//
//  Created by Istvan Sipos on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "GraphDataSource.h"

@class Program;

@interface GraphDataSourceProgramRunTime : GraphDataSource

@property (nonatomic, strong) Program *program;

@end
