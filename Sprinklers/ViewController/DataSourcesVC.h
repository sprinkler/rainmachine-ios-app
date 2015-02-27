//
//  DataSourcesVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"
#import "ParserCell.h"

@class SettingsVC;

@interface DataSourcesVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate, ParserCellDelegate, SprinklerResponseProtocol>

@property (nonatomic, strong) SettingsVC *parent;
@property (nonatomic, strong) Parser *parser;
@property (nonatomic, strong) Parser *unsavedParser;

@end
