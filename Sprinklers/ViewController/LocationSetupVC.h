//
//  LocationSetupVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class ColoredBackgroundButton;

@interface LocationSetupVC : UIViewController <MKMapViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UILabel *selectLocationLabel;
@property (nonatomic, weak) IBOutlet UITextField *locationTextField;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UITableView *autoCompleteResultsTableView;
@property (nonatomic, weak) IBOutlet ColoredBackgroundButton *nextButton;

@end
