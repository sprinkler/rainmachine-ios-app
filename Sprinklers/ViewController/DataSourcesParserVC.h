//
//  DataSourcesParserVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"

@class Parser;
@class SettingsVC;

@interface DataSourcesParserVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) Parser *parser;
@property (nonatomic, strong) SettingsVC *parent;

@end
