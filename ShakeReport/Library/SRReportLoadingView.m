//
//  SRReportLoadingView.m
//  ShakeReport
//
//  Created by Jeremy Templier on 9/19/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRReportLoadingView.h"
#import <QuartzCore/QuartzCore.h>

@implementation SRReportLoadingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
        self.layer.cornerRadius = 5;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, CGRectGetWidth(frame), 30)];
        label.text = @"Sending Report";
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:15.f];
        [self addSubview:label];
        if (!_progressView) {
            _progressView =[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            _progressView.frame = CGRectMake(CGRectGetWidth(frame) * 0.1,
                                             CGRectGetHeight(frame)*0.5 - CGRectGetHeight(_progressView.bounds)*0.5,
                                             CGRectGetWidth(frame) * 0.8,
                                             CGRectGetHeight(_progressView.bounds));
            [self addSubview:_progressView];
        }
    }
    return self;
}


@end
