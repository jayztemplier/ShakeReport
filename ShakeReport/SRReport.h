//
//  SRReport.h
//  ShakeReport
//
//  Created by Jeremy Templier on 04/07/15.
//  Copyright (c) 2015 Jayztemplier. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString* (^SRCustomInformationBlock)();

@interface SRReport : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *dumpedView;
@property (nonatomic, readonly) NSString *logs;
@property (nonatomic, strong) UIImage *screenshot;
@property (nonatomic, readonly) NSDictionary *systemInformation;
@property (nonatomic, readonly) NSString *screenCaptureVideoPath;
@property (readwrite, nonatomic, copy) SRCustomInformationBlock customInformationBlock;

// Logs
- (NSString *)logFilePath;

// Custom Info
- (NSString *)customInformation;

// Crash
- (NSString *)crashReport;
- (void)saveToCrashFile:(NSString *)crashContent;
- (NSString *)crashFilePath;

@end
