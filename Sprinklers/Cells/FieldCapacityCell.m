//
//  FieldCapacityCell.m
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "FieldCapacityCell.h"

@implementation FieldCapacityCell {
    int _fieldCapacity;
}

- (void)awakeFromNib {
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

#pragma mark - Accessors

- (void)setFieldCapacity:(int)fieldCapacity {
    _fieldCapacity = fieldCapacity;
    
    NSMutableAttributedString *fieldCapacityAttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"My soil type can store %d days of water in the summer",fieldCapacity] attributes:nil];
    [fieldCapacityAttributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:17.0] range:NSMakeRange(0, fieldCapacityAttributedString.length)];
    [fieldCapacityAttributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0] range:NSMakeRange(23, [NSString stringWithFormat:@"%d days",fieldCapacity].length)];
        
    self.fieldCapacityLabel.attributedText = fieldCapacityAttributedString;
    self.fieldCapacityLabel.numberOfLines = 0;
}

- (int)fieldCapacity {
    return _fieldCapacity;
}

@end
