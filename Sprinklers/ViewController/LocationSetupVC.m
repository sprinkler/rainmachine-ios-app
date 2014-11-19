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

const NSInteger LocationSetup_MapView_StartRegionSizeMeters = 1000.0;

#pragma mark -

@interface LocationSetupVC ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geocoder;

- (BOOL)initializeLocationServices;
- (void)displayLocationServicesDisabledAlert;

@property (nonatomic, assign) BOOL mapViewLocatedUser;
@property (nonatomic, strong) MKUserLocation *userLocation;

- (void)showAutoCompleteResultsAnimated:(BOOL)animate;
- (void)hideAutoCompletResultAnimated:(BOOL)animate;

@end

#pragma mark -

@implementation LocationSetupVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Location";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.locationTextField.tintColor = self.locationTextField.textColor;
    }
    
    [self.nextButton setCustomBackgroundColorFromComponents:kSprinklerBlueColor];
    
    self.mapView.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
    self.mapView.layer.borderWidth = 1.0;
    
    self.autoCompleteResultsTableView.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
    self.autoCompleteResultsTableView.layer.borderWidth = 1.0;
    
    if (![self initializeLocationServices]) {
        [self displayLocationServicesDisabledAlert];
        return;
    }
    
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.hidden = NO;
    self.autoCompleteResultsTableView.hidden = YES;
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper methods

- (BOOL)initializeLocationServices {
    if (![CLLocationManager locationServicesEnabled]) return NO;
    
    if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.geocoder = [[CLGeocoder alloc] init];
    
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

- (void)showAutoCompleteResultsAnimated:(BOOL)animate {
    self.mapView.hidden = NO;
    self.autoCompleteResultsTableView.hidden = NO;
    self.mapView.alpha = 1.0;
    self.autoCompleteResultsTableView.alpha = 0.0;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.mapView.alpha = 0.0;
        self.autoCompleteResultsTableView.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.mapView.hidden = YES;
        self.autoCompleteResultsTableView.hidden = NO;
    }];
}

- (void)hideAutoCompletResultAnimated:(BOOL)animate {
    self.mapView.hidden = NO;
    self.autoCompleteResultsTableView.hidden = NO;
    self.mapView.alpha = 0.0;
    self.autoCompleteResultsTableView.alpha = 1.0;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.mapView.alpha = 1.0;
        self.autoCompleteResultsTableView.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.mapView.hidden = NO;
        self.autoCompleteResultsTableView.hidden = YES;
    }];
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField {
    [self showAutoCompleteResultsAnimated:YES];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    [textField resignFirstResponder];
    [self hideAutoCompletResultAnimated:YES];
    return YES;
}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    if (textField.text.length) {
        [[GeocodingRequestAutocomplete autocompleteGeocodingRequestWithInputString:textField.text] executeRequestWithCompletionHandler:^(id result, NSError *error) {
            
        }];
    }
    return YES;
}

#pragma mark - Map view delegate

- (void)mapView:(MKMapView*)mapView didUpdateUserLocation:(MKUserLocation*)userLocation {
    if (self.mapViewLocatedUser) return;
    
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude),
                                                                             LocationSetup_MapView_StartRegionSizeMeters,
                                                                             LocationSetup_MapView_StartRegionSizeMeters);
    MKCoordinateRegion adjustedRegion = [mapView regionThatFits:coordinateRegion];
    [mapView setRegion:adjustedRegion animated:YES];
    
    self.userLocation = userLocation;

    [[GeocodingRequestReverse reverseGeocodingRequestWithLocation:self.userLocation.location] executeRequestWithCompletionHandler:^(GeocodingAddress *result, NSError *error) {
        self.locationTextField.text = result.closestMatchingAddressComponent;
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
    
    self.mapViewLocatedUser = YES;
}

- (void)mapView:(MKMapView*)mapView didFailToLocateUserWithError:(NSError*)error {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

@end
