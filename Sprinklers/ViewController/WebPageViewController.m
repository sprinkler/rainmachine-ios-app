//
//  WebPageViewController.m
//  SportsFan_v4
//
//  Created by Daniel Cristolovean on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WebPageViewController.h"
#import "Additions.h"

@implementation WebPageViewController

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (id)initWithURL:(NSString *)u {
    if (self = [self init]) {
        _showLoading = YES;
		url = u;
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"My RainMachines" style:UIBarButtonItemStyleBordered target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    for (UIView *subView in _webView.subviews) {
        if ([subView isKindOfClass:[UIScrollView class]]) {
            currentScrollView = (UIScrollView *)subView;
            currentScrollView.delegate = self;
        }
    }
    
    _toolbar.barStyle = UIBarStyleBlackOpaque;
    
    pull = [[PullToRefreshView alloc] initWithScrollView:currentScrollView];
    pull.delegate = self;
    [currentScrollView addSubview:pull];
    
    if (url) {
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    }
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:@"ApplicationDidBecomeActive" object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dismissHud {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    hud = nil;
}

- (void)appDidBecomeActive {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - PullToRefresh delegate

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    if (url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    }
}

#pragma mark - UIWebView delegate

//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    BOOL result = _Authenticated;
//    if (!_Authenticated) {
//        _FailedRequest = request;
//        NSURLConnection *connnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
//        [connnection start];
//    }
//    return result;
//}
//
//- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
//    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
//        NSURL *baseURL = [_FailedRequest URL];
//        if ([challenge.protectionSpace.host isEqualToString:baseURL.host]) {
//            NSLog(@"trusting connection to host %@", challenge.protectionSpace.host);
//            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
//        } else
//            NSLog(@"Not trusting connection to host %@", challenge.protectionSpace.host);
//    }
//    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
//    _Authenticated = YES;
//    [connection cancel];
//    [self.webView loadRequest:_FailedRequest];
//}

//V2

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"Did start loading: %@ auth:%d", [[request URL] absoluteString], _Authenticated);
    
    if (!_Authenticated) {
        _Authenticated = NO;
        
        urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
        [urlConnection start];
        
        return NO;
    }
    
    return YES;
}


#pragma mark - NURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"WebController Got auth challange via NSURLConnection");
    
    if ([challenge previousFailureCount] == 0) {
        _Authenticated = YES;
        
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        
        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
        
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"WebController received response via NSURLConnection");
    
    // remake a webview call now that authentication has passed ok.
    _Authenticated = YES;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    
    // Cancel the URL connection otherwise we double up (webview + url connection, same url = no good!)
    [urlConnection cancel];
}

// We use this method is to accept an untrusted site which unfortunately we need to do, as our PVM servers are self signed.
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

//end V2

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (_showLoading) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = [NSString stringWithFormat:@"Connecting to %@...", self.title];;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self dismissHud];
    [pull finishedLoading];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self dismissHud];
    [pull finishedLoading];
}

#pragma mark - Dealloc

- (void)viewDidUnload {
    [self setWebView:nil];
    [self setToolbar:nil];
    [super viewDidUnload];
}

@end
