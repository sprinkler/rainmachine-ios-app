//
//  CCTBackButtonActionHelper.m
//  BackButtonAction
//
//  Created by Weipin Xia on 5/13/13.
//  Copyright (c) 2013 Weipin Xia. All rights reserved.
//

#import "CCTBackButtonActionHelper.h"

@implementation CCTBackButtonActionHelper

+ (CCTBackButtonActionHelper*)sharedInstance {
    static dispatch_once_t once;
    static CCTBackButtonActionHelper *instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });

    return instance;
}

- (BOOL)navigationController:(UINavigationController *)navigationController
               navigationBar:(UINavigationBar *)navigationBar
               shouldPopItem:(UINavigationItem *)item {
    if (navigationController.topViewController.navigationItem != item) {
        return YES;
    }

    UIViewController<CCTBackButtonActionHelperProtocol>* controller = nil;
    controller = (UIViewController<CCTBackButtonActionHelperProtocol>*)navigationController.topViewController;
    if ([controller respondsToSelector:@selector(cct_navigationBar:willPopItem:)]) {
        return [controller cct_navigationBar:navigationBar willPopItem:item];
    }
    
    return YES;
    
    // Matyas: I modified the class and use a delegate because during the swipe gesture in iOS 7 the topViewController is not the one on top.
    // Commented this aproach because the back-swipe gesture was causing problems (see issue #61)
//    if (self.delegate) {
//        return [self.delegate cct_navigationBar:navigationBar willPopItem:item];
//    }
//    
//    return YES;
}

@end
