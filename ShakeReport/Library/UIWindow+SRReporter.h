//
//  UIWindow+SRReporter.h
//  ShakeReport
//
//  Created by Jeremy Templier on 5/29/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWindow (SRReporter)

- (void)SR_motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event;
- (void)SR_sendEvent:(UIEvent *)event;

@end
