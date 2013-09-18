//
//  UIWindow+SRReporter.m
//  ShakeReport
//
//  Created by Jeremy Templier on 5/29/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "UIWindow+SRReporter.h"
#import "SRMethodSwizzler.h"
#import "SRReporter.h"
#import "SRDefines.h"

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

- (void)SR_sendEvent:(UIEvent *)event
{
    [self SR_sendEvent:event];
    [[NSNotificationCenter defaultCenter] postNotificationName:CRUIEventNotification object:event];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {}

@end
