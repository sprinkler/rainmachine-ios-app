//
//  ParserCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Parser;
@protocol ParserCellDelegate;

@interface ParserCell : UITableViewCell

@property (nonatomic, strong) Parser *parser;
@property (nonatomic, weak) id<ParserCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UILabel *parserNameLabel;
@property (nonatomic, weak) IBOutlet UISwitch *parserEnabledSwitch;

- (IBAction)onActivateParser:(id)sender;

@end

#pragma mark -

@protocol ParserCellDelegate <NSObject>

- (void)parserCell:(ParserCell*)parserCell activateParser:(BOOL)activateParser;

@end
