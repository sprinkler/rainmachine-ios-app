//
//  ProgramsVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 05/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class SettingsVC;
@class Program;

@interface ProgramsVC : BaseLevel2ViewController <UITableViewDelegate, UITableViewDataSource, SprinklerResponseProtocol>

@property (weak, nonatomic) SettingsVC *parent;
@property (strong, nonatomic) NSMutableArray *programs;

- (void)setProgram:(Program*)p withIndex:(int)i;
- (void)addProgram:(Program*)p;
- (int)serverTimeFormat;

@end
