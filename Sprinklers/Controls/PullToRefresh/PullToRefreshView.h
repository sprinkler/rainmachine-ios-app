//
//  PullToRefreshView.h
//  SportsFan_v4
//
//  Created by Daniel Cristolovean on 6/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef enum {
    PullToRefreshViewStateNormal = 0,
    PullToRefreshViewStateReady,
    PullToRefreshViewStateLoading
} PullToRefreshViewState;

@protocol PullToRefreshViewDelegate;

@interface PullToRefreshView : UIView {
    PullToRefreshViewState state;
    
    UILabel *lastUpdatedLabel;
    UILabel *statusLabel;
    CALayer *arrowImage;
    UIActivityIndicatorView *activityView;
}

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) id<PullToRefreshViewDelegate> delegate;

- (void)refreshLastUpdatedDate;
- (void)finishedLoading;
- (void)setState:(PullToRefreshViewState)state_;
- (void)setStatusLabelText:(NSString *)text;
- (id)initWithScrollView:(UIScrollView *)scrollView;

@end

@protocol PullToRefreshViewDelegate <NSObject>

@optional

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;
- (NSDate *)pullToRefreshViewLastUpdated:(PullToRefreshView *)view;

@end
