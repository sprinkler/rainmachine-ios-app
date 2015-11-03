//
//  DataSourcesParserParameterVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"

@class Parser;
@class ParserParameter;
@class DataSourcesParserVC;

@interface DataSourcesParserParameterVC : BaseLevel2ViewController <UITextFieldDelegate>

@property (nonatomic, weak) DataSourcesParserVC *parent;
@property (nonatomic, strong) Parser *parser;
@property (nonatomic, strong) ParserParameter *parserParameter;

@end
