//
//  LocationSetupVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "LocationSetupVC.h"
#import "ColoredBackgroundButton.h"
#import "Constants.h"
#import "Additions.h"
#import "GeocodingAddress.h"
#import "GeocodingRequest.h"
#import "GeocodingRequestReverse.h"
#import "GeocodingRequestAutocomplete.h"
#import "MBProgressHUD.h"
#import <CoreLocation/CoreLocation.h>

const double LocationSetup_MapView_InitializeTimeout                = 5.0;
const double LocationSetup_MapView_StartRegionSizeMeters            = 1000.0;
const double LocationSetup_Autocomplete_ReloadResultsTimeInterval   = 0.5;

#pragma mark -

@interface LocationSetupVC ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSDate *lastAutocompleteReloadResultsDate;
@property (nonatomic, strong) NSString *lastAutocompleteSearchString;

- (BOOL)initializeLocationServices;
- (void)displayLocationServicesDisabledAlert;

@property (nonatomic, assign) BOOL startLocationFound;
@property (nonatomic, strong) NSString *lastSelectedLocation;

@end

#pragma mark -

@implementation LocationSetupVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;
    
    self.title = @"Location";
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleDone target:self action:@selector(onNext:)];
    
    if (![self initializeLocationServices]) {
        [self displayLocationServicesDisabledAlert];
        return;
    }
    
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    self.mapView.settings.myLocationButton = YES;
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self performSelector:@selector(hideHUDAddedToView) withObject:nil afterDelay:LocationSetup_MapView_InitializeTimeout];
}

- (void)hideHUDAddedToView {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.mapView addObserver:self forKeyPath:@"myLocation" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.startLocationFound) {
        [self.mapView removeObserver:self forKeyPath:@"myLocation"];
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (object == self.mapView && [keyPath isEqualToString:@"myLocation"] && !self.startLocationFound) {
        self.startLocationFound = YES;
        [self.mapView removeObserver:self forKeyPath:@"myLocation"];
        
        float zoom = [GMSCameraPosition zoomAtCoordinate:self.mapView.myLocation.coordinate
                                               forMeters:LocationSetup_MapView_StartRegionSizeMeters
                                               perPoints:self.mapView.bounds.size.width];
        
        [self.mapView animateToCameraPosition:[GMSCameraPosition cameraWithLatitude:self.mapView.myLocation.coordinate.latitude
                                                                          longitude:self.mapView.myLocation.coordinate.longitude
                                                                               zoom:zoom]];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideHUDAddedToView) object:nil];
        [[GMSGeocoder geocoder] reverseGeocodeCoordinate:self.mapView.myLocation.coordinate completionHandler:^(GMSReverseGeocodeResponse *geocodeResponse, NSError *error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            
            if (geocodeResponse) {
                GMSAddress *address = geocodeResponse.firstResult;
                self.locationSearchBar.placeholder = address.locality;
                self.lastSelectedLocation = address.locality;
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper methods

- (BOOL)initializeLocationServices {
    if (![CLLocationManager locationServicesEnabled]) return NO;
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    return YES;
}

- (void)displayLocationServicesDisabledAlert {
    if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Location Services disabled"
                                                                                 message:@"Allow RainMachine to access your location in your phone's settings."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Location Services disabled"
                                                            message:@"Allow RainMachine to access your location in your phone's settings."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark - Search display controller delegate

- (void)reloadAutocompleteResultsForSearchString:(NSString*)searchString {
    self.lastAutocompleteReloadResultsDate = [NSDate date];
}

- (BOOL)searchDisplayController:(UISearchDisplayController*)controller shouldReloadTableForSearchString:(NSString*)searchString {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadAutocompleteResultsForSearchString:) object:self.lastAutocompleteSearchString];
    [self performSelector:@selector(reloadAutocompleteResultsForSearchString:) withObject:searchString afterDelay:LocationSetup_Autocomplete_ReloadResultsTimeInterval];
    
    self.lastAutocompleteSearchString = searchString;
    
    return YES;
}

#pragma mark - Search bar delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {

}

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar {
}

#pragma mark - Table view datasource

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (IBAction)onNext:(id)sender {
    
}

@end
