//
//  DevicesCellType1.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Sprinkler;

@interface DevicesCellType1 : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *labelInfo;
@property (strong, nonatomic) IBOutlet UILabel *labelMainTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelMainSubtitle;
@property (weak, nonatomic) IBOutlet UIImageView *disclosureImageView;

@property (strong, nonatomic) Sprinkler *sprinkler;

@end
