//
//  UIWindow+SRReporter.m
//  ShakeReport
//
//  Created by Jeremy Templier on 5/29/13.
//  Copyright (c) 2013 Jayztemplier. All rights reserved.
//

#import "UIWindow+SRReporter.h"
#import "SRMethodSwizzler.h"
#import "SRReporter.h"

@implementation UIWindow (SRReporter)

- (void)SR_motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    [[SRReporter reporter] sendNewReport];
    [self SR_motionEnded:motion withEvent:event];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {}

@end
