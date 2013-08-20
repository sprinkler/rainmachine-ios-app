//
//  WebPageViewController.h
//  SportsFan_v4
//
//  Created by Daniel Cristolovean on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "PullToRefreshView.h"

@interface WebPageViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate, PullToRefreshViewDelegate, NSURLConnectionDataDelegate> {
    MBProgressHUD *hud;   
    NSString *url;
    UIScrollView *currentScrollView;
    PullToRefreshView *pull;
    UINavigationBar *bar;
    NSURLRequest *_FailedRequest;
    BOOL _Authenticated;
    NSURLConnection *urlConnection;
}

@property (retain, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic) BOOL showLoading;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

- (id)initWithURL:(NSString *)url;

@end
