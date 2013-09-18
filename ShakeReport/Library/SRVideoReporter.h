//
//  SRVideoReporter.h
//  ShakeReport
//
//  Created by Jeremy Templier on 9/22/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRReporter.h"

@interface SRVideoReporter : SRReporter

@property (nonatomic, assign) BOOL screenCaptureEnabled;

- (void)startScreenRecorder;
- (void)startScreenRecorderWithMaxDurationPerVideo:(NSTimeInterval)timeInterval;

@end
