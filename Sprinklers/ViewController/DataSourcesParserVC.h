//
//  DataSourcesParserVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"
#import "Protocols.h"
#import "CCTBackButtonActionHelper.h"

@class Parser;
@class DataSourcesVC;

@interface DataSourcesParserVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, SprinklerResponseProtocol, CCTBackButtonActionHelperProtocol>

@property (nonatomic, strong) DataSourcesVC *parent;
@property (nonatomic, strong) Parser *parser;
@property (nonatomic, strong) Parser *unsavedParser;
@property (nonatomic, assign) BOOL showInitialUnsavedAlert;

@end
