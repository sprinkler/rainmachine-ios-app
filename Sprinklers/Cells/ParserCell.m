//
//  ParserCell.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "ParserCell.h"
#import "Parser.h"

@implementation ParserCell

- (void)setParser:(Parser*)parser {
    _parser = parser;
    
    self.parserNameLabel.text = parser.name;
    self.parserEnabledSwitch.on = parser.enabled;
}

- (IBAction)onActivateParser:(id)sender {
    [self.delegate parserCell:self activateParser:self.parserEnabledSwitch.isOn];
}

@end
