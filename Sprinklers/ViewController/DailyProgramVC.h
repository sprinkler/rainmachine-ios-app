//
//  DailyProgramVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 23/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class Program;
@class ProgramsVC;

@interface DailyProgramVC : BaseLevel2ViewController <SprinklerResponseProtocol, CellButtonDelegate>

@property (strong, nonatomic) Program *program;
@property (weak, nonatomic) ProgramsVC *parent;

@end
