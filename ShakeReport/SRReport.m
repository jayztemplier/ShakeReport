//
//  SRReport.m
//  ShakeReport
//
//  Created by Jeremy Templier on 04/07/15.
//  Copyright (c) 2015 Jayztemplier. All rights reserved.
//

#import "SRReport.h"
#import "SRReporter.h"

@implementation SRReport

#pragma mark Screenshot

- (UIImage *)takeScreenshot
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(window.bounds.size);
    
    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)screenshot {
        if (!_screenshot) {
            _screenshot = [self takeScreenshot];
        }
    return _screenshot;
}

#pragma mark View Hierarchy
- (NSString *)dumpedView
{
    if (_dumpedView) {
        return _dumpedView;
    }
#ifdef DEBUG
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    SEL selector = NSSelectorFromString(@"recursiveDescription");
    IMP imp = [keyWindow methodForSelector:selector];
    NSString *(*func)(id, SEL) = (void *)imp;
    NSString *dump = func(keyWindow, selector);
    _dumpedView = dump;
    return _dumpedView;
#else
    return @"";
#endif
}

#pragma mark System Information
- (NSDictionary *)systemInformation
{
    return @{
             @"os_version": [[UIDevice currentDevice] systemVersion],
             @"device_model" : [[UIDevice currentDevice] model]
             };
}

#pragma mark Logs
- (NSString *)logFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"console.log"];
    return logPath;
}

- (NSString *)logs
{
    NSString *logPath = [self logFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
        NSString *logs = [NSString stringWithContentsOfFile:logPath encoding:NSUTF8StringEncoding error:nil];
        return logs;
    }
    return @"";
}

#pragma mark Video
- (NSString * )screenCaptureVideoPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:@"screen_capture.mov"];
    return myPathDocs;
}

#pragma mark Custom info
- (NSString *)customInformation
{
    if (_customInformationBlock) {
        return _customInformationBlock();
    }
    return nil;
}

#pragma mark Crash
- (NSString *)crashReport
{
    NSString *crashFilePath = [self crashFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:crashFilePath]) {
        NSString *crash = [NSString stringWithContentsOfFile:crashFilePath encoding:NSUTF8StringEncoding error:nil];
        [[SRReporter reporter] setCrashFlag:NO];
        return crash;
    }
    return nil;
}

- (void)saveToCrashFile:(NSString *)crashContent
{
    if (crashContent) {
        NSString *filePath = [self crashFilePath];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        [crashContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [[SRReporter reporter] setCrashFlag:YES];
    }
}

- (NSString *)crashFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"crash.log"];
    return logPath;
}


@end
