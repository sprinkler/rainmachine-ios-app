//
//  DataSourcesParserParameterVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "DataSourcesParserParameterVC.h"
#import "DataSourcesParserVC.h"
#import "Parser.h"
#import "Additions.h"

#pragma mark -

@interface DataSourcesParserParameterVC ()

@property (nonatomic, weak) IBOutlet UILabel *parameterNameLabel;
@property (nonatomic, weak) IBOutlet UITextField *parameterValueTextField;

- (NSString*)stringValueFromParserParameter:(ParserParameter*)parserParameter;

@end

#pragma mark -

@implementation DataSourcesParserParameterVC

#pragma mark - Init

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.parameterValueTextField.tintColor = [UIColor blackColor];
    }
    
    self.title = self.parser.name;
    self.parameterNameLabel.text = self.parserParameter.name;
    self.parameterValueTextField.text = [self stringValueFromParserParameter:self.parserParameter];
    
    if (self.parserParameter.parameterType == ParserParameterTypeNumber) {
        self.parameterValueTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    } else {
        self.parameterValueTextField.keyboardType = UIKeyboardTypeDefault;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.parameterValueTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.parameterValueTextField.text.length) {
        if (self.parserParameter.parameterType == ParserParameterTypeNumber) {
            int intValue = [self.parameterValueTextField.text intValue];
            double doubleValue = [self.parameterValueTextField.text doubleValue];
            
            if (intValue == doubleValue) self.parserParameter.value = @(intValue);
            else self.parserParameter.value = @(doubleValue);
        } else {
            self.parserParameter.parameterType = ParserParameterTypeString;
            self.parserParameter.value = self.parameterValueTextField.text;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper methods

- (NSString*)stringValueFromParserParameter:(ParserParameter*)parserParameter {
    if (parserParameter.parameterType == ParserParameterTypeString) return parserParameter.value;
    if (parserParameter.parameterType == ParserParameterTypeNumber) return [parserParameter.value stringValue];
    return @"";
}

#pragma mark - UITextField delegate

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    if (self.parserParameter.parameterType != ParserParameterTypeNumber) return YES;
        
    if (!string.length) return YES;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setDecimalSeparator:@"."];
    
    NSString *updatedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSNumber *number = [numberFormatter numberFromString:updatedText];
    
    if (number) return YES;
    return NO;
}

@end
