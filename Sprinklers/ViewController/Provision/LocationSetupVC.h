//
//  LocationSetupVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "DiscoveredSprinklers.h"
#import "Protocols.h"
#import "ProvisionNameSetupVC.h"
#import "BaseLevel2ViewController.h"

@class ColoredBackgroundButton;

@interface LocationSetupVC : UIViewController <GMSMapViewDelegate, SprinklerResponseProtocol, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar *locationSearchBar;
@property (nonatomic, weak) IBOutlet UIView *mapContentView;
@property (nonatomic, weak) IBOutlet GMSMapView *mapView;
@property (strong, nonatomic) DiscoveredSprinklers *sprinkler;
@property (nonatomic, weak) ProvisionNameSetupVC *delegate;

- (IBAction)onNext:(id)sender;

@end
