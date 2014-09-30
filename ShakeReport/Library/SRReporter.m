//
//  SRReporter.m
//  ShakeReport
//
//  Created by Jeremy Templier on 5/29/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRReporter.h"
#import "SRMethodSwizzler.h"
#import "UIWindow+SRReporter.h"
#import "NSData+Base64.h"
#import "NSString+HTML.h"
#import <QuartzCore/QuartzCore.h>
#import "SRReportViewController.h"
#import "SRHTTPClient.h"
#import "SRReportLoadingView.h"
#import "SRImageEditorViewController.h"
#import "UIWindow+SRReporter.h"

#define kCrashFlag @"kCrashFlag"
#define SR_LOGS_ENABLED NO

void uncaughtExceptionHandler(NSException *exception) {
    [[SRReporter reporter] onCrash:exception];
}


@interface SRReporter () <UIAlertViewDelegate>
@property (nonatomic,  strong) MFMailComposeViewController *mailController;
@property (nonatomic, strong) UIImage *tempScreenshot;
@property (nonatomic, strong) SRReportLoadingView *loadingView;
@property (nonatomic, assign) BOOL composerDisplayed;
@end

@implementation SRReporter
@synthesize mailController;

+ (instancetype)reporter {
    static SRReporter *__sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[self alloc] init];
    });
    return __sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _lastSessionCrashed = [self crashFlag];
        _displayReportComposerWhenShakeDevice = YES;
        _recordsCrashes = YES;
    }
    return self;
}

- (void)startListenerConnectedToBackendURL:(NSURL *)url
{
    _backendURL = url;
    [self startListener];
}


- (void)startListener
{
    [self startLog2File];
    if (_recordsCrashes) {
        [self startCrashExceptionHandler];
    }
    static BOOL methodSwizzled = NO;
    if (!methodSwizzled) {
        SwizzleInstanceMethod([UIWindow class], @selector(motionEnded:withEvent:), @selector(SR_motionEnded:withEvent:));
        methodSwizzled = YES;
    }
    NSLog(@"Shake Report is now listening to your application.");
}

- (void)stopListener
{
}


#pragma mark Logs
- (void)startLog2File
{
    if (!isatty(STDERR_FILENO)) {
        NSString *logPath = [self logFilePath];
        [[NSFileManager defaultManager] removeItemAtPath:logPath error:nil];
        freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
    }
}

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

#pragma mark Report
- (BOOL)canSendNewReport
{
    return !_composerDisplayed;
}

- (void)displayReportComposer
{
    if (![self canSendNewReport]) {
        return;
    }
    if(SR_LOGS_ENABLED) NSLog(@"Send New Report");
    if (_backendURL) {
        _tempScreenshot = [self screenshot];
//        SRReportViewController *controller = [SRReportViewController composer];
//        controller.delegate = self;
        SRImageEditorViewController *controller = [SRImageEditorViewController controllerWithImage:_tempScreenshot];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        if ([navController.navigationBar respondsToSelector:@selector(setTranslucent:)]) {
            [navController.navigationBar setTranslucent:NO];
        }
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        [self presentReportComposer:navController inViewController:window.rootViewController];
    } else {
        [self showMailComposer];
    }
    _composerDisplayed = YES;
}

- (void)presentReportComposer:(UIViewController *)composerController inViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController) {
        [self presentReportComposer:composerController inViewController:rootViewController.presentedViewController];
    } else {
        [rootViewController presentViewController:composerController animated:YES completion:NO];
    }
}

- (void)viewControllerDidPressCancel:(UIViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    _composerDisplayed = NO;
    [self setCrashFlag:NO];
}

#pragma mark - Crash Report
- (void)startCrashExceptionHandler
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    if ([self crashFlag]) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Crash detected" message:@"Do you want to send the report?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [alert show];
    }
}

- (void)onCrash:(NSException *)exception
{
    NSMutableString *crashString = [NSMutableString string];
    [crashString appendString:@"-------------- CRASH --------------\n"];
    [crashString appendFormat:@"CRASH: %@\n", exception];
    [crashString appendFormat:@"Stack Trace: %@\n", [exception callStackSymbols]];
    [crashString appendString:@"-----------------------------------"];
    [[SRReporter reporter] saveToCrashFile:crashString];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self displayReportComposer];
    } else {
        [self setCrashFlag:NO];
    }
}

- (void)setCrashFlag:(BOOL)flag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:flag forKey:kCrashFlag];
    [userDefaults synchronize];
    if (!flag) {
        NSString *filePath = [self crashFilePath];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}

- (BOOL)crashFlag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:kCrashFlag];
}

- (NSString *)crashReport
{
    NSString *crashFilePath = [self crashFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:crashFilePath]) {
        NSString *crash = [NSString stringWithContentsOfFile:crashFilePath encoding:NSUTF8StringEncoding error:nil];
        [self setCrashFlag:NO];
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
        [self setCrashFlag:YES];
    }
}

- (NSString *)crashFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"crash.log"];
    return logPath;
}
#pragma mark Screenshot
- (void)saveImageToDisk:(UIImage *)image
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"screenshot.png"];
    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
}

- (UIImage *)imageFromDisk
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    UIImage *image = [UIImage imageWithContentsOfFile:[[paths objectAtIndex:0] stringByAppendingPathComponent:@"screenshot.png"]];
    return image;
}

- (UIImage *)screenshot
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(window.bounds.size);

    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self saveImageToDisk:image];
    return image;
}

#pragma mark View Hierarchy
- (NSString *)viewHierarchy
{
#ifdef DEBUG
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    SEL selector = NSSelectorFromString(@"recursiveDescription");
    IMP imp = [keyWindow methodForSelector:selector];
    NSString *(*func)(id, SEL) = (void *)imp;
    NSString *dump = func(keyWindow, selector);
    return dump;
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

#pragma mark Custom Information
- (void)setCustomInformationBlock:(NSString* (^)())block
{
    _customInformationBlock = block;
}


- (NSString *)customInformation
{
    if (_customInformationBlock) {
        return _customInformationBlock();
    }
    return nil;
}

#pragma mark Mail Composer
- (void)addAttachmentsToMailComposer:(MFMailComposeViewController *)mailComposer
{
    // Fetch Screenshot data
    UIImage *screenshot = [self screenshot];
    NSData *imageData = UIImageJPEGRepresentation(screenshot ,1.0);
    
    // Logs
    NSString *logs = [self logs];
    NSData* logsData = [logs dataUsingEncoding:NSUTF8StringEncoding];
    
    // View Hierarchy (Root=Window)
    NSString *viewDump = [self viewHierarchy];
    NSData* viewData = [viewDump dataUsingEncoding:NSUTF8StringEncoding];
    
    // Crash Report if we registered a crash
    NSString *crashReport = [self crashReport];
    if (!crashReport) {
        crashReport = @"No Crash";
    }
    NSData* crashData = [crashReport dataUsingEncoding:NSUTF8StringEncoding];
    
    // We attache all the information to the email
    [mailComposer addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"screenshot.jpeg"];
    [mailComposer addAttachmentData:logsData mimeType:@"text/plain" fileName:@"console.log"];
    [mailComposer addAttachmentData:viewData mimeType:@"text/plain" fileName:@"viewDump.log"];
    [mailComposer addAttachmentData:crashData mimeType:@"text/plain" fileName:@"crash.log"];
    NSString *message = [NSString stringWithFormat:@"Hey! I noticed something wrong with the app, here is some information.\nDevice model: %@\nOS version:%@", [self systemInformation][@"device_model"], [self systemInformation][@"os_version"]];
    [mailComposer setMessageBody:message isHTML:NO];
    
    //Custom Information
    NSString *additionalInformation = [self customInformation];
    if (additionalInformation) {
        NSData* additionalInformationData = [additionalInformation dataUsingEncoding:NSUTF8StringEncoding];
        [mailComposer addAttachmentData:additionalInformationData mimeType:@"text/plain" fileName:@"additionalInformation.log"];
    }
}

- (void)showMailComposer
{
    if (mailController) {
        return;
    }
    mailController = [[MFMailComposeViewController alloc] init];
    mailController.mailComposeDelegate = self;
    mailController.delegate = self;
    [mailController setSubject:@"[SRReporter] New Report"];
    if (_defaultEmailAddress) {
        [mailController setToRecipients:@[_defaultEmailAddress]];
    }
    mailController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self addAttachmentsToMailComposer:mailController];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [self presentReportComposer:mailController inViewController:window.rootViewController];
    _composerDisplayed = YES;
}

- (void)mailComposeController:(MFMailComposeViewController*)mailController didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (self.mailController) {
        [self.mailController dismissViewControllerAnimated:YES completion:nil];
        self.mailController = nil;
        _composerDisplayed = NO;
    }
}

#pragma mark ShareReport Server API
- (NSDictionary *)paramsForHTTPReportWithTitle:(NSString *)title andMessage:(NSString *)message
{
    UIImage *screenshot = [self imageFromDisk];
    if (!screenshot) {
        screenshot = [self screenshot];
    }
    _tempScreenshot = nil;
    NSData *imageData = UIImageJPEGRepresentation(screenshot ,1.0);
    NSString *base64ImageString = [imageData base64EncodingWithLineLength:(int)imageData.length];
    NSString *logs = [self logs];
    NSString *viewDump = [self viewHierarchy];
    NSString *crashReport = [self crashReport];
    
    // let's construct the URL
    NSMutableDictionary *reportParams = [NSMutableDictionary dictionary];
    reportParams[@"report[screenshot]"] = base64ImageString;
    reportParams[@"report[logs]"] = logs;
    reportParams[@"report[dumped_view]"] = viewDump;
    reportParams[@"report[title]"] = (title && title.length ? title : @"No title");
    reportParams[@"report[message]"] = (message && message.length ? message : @"No message");
    reportParams[@"report[device_model]"] = [self systemInformation][@"device_model"];
    reportParams[@"report[os_version]"] = [self systemInformation][@"os_version"];
    reportParams[@"report[message]"] = (message && message.length ? message : @"No message");
    if (_customInformationBlock) {
        NSString *customInfo = [self customInformation];
        if (customInfo && customInfo.length) {
            reportParams[@"report[custom_info]"] = customInfo;
        }
    }
    if (crashReport) {
        reportParams[@"report[crash_logs]"] = crashReport;
    }
    return reportParams;
}

- (NSMutableURLRequest *)requestForHTTPReportWithTitle:(NSString *)title andMessage:(NSString *)message
{
    NSMutableDictionary *reportParams = [[self paramsForHTTPReportWithTitle:title andMessage:message] mutableCopy];
    SRHTTPClient *httpClient = [[SRHTTPClient alloc] initWithBaseURL:_backendURL];
    if (_applicationToken) {
        [httpClient setDefaultHeader:@"X-APPLICATION-TOKEN" value:_applicationToken];
    }
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"api/reports.json" parameters:reportParams];
    return request;
}

- (void)sendToServerWithTitle:(NSString *)title andMessage:(NSString *)message
{
    if (!_backendURL) {
        return;
    }
    NSMutableURLRequest *request = [self requestForHTTPReportWithTitle:title andMessage:message];
    NSURLConnection *urlConnection = [NSURLConnection connectionWithRequest:request delegate:self];
    [urlConnection start];
}

#pragma mark - Loading View
- (void)displayProgressBarWithPercentage:(CGFloat)percentage
{
    if (!_loadingView) {
        _loadingView = [[SRReportLoadingView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    }
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    _loadingView.center = CGPointMake(CGRectGetMidX(window.bounds), CGRectGetMidY(window.bounds));
    _loadingView.progressView.progress = percentage;
    [window addSubview:_loadingView];
}

#pragma mark - SRReportViewController delegate
- (void)reportControllerDidPressSend:(SRReportViewController *)controller
{
    NSString *title = controller.title;
    NSString *message = controller.message;
    [self sendToServerWithTitle:title andMessage:message];
    [controller dismissViewControllerAnimated:YES completion:nil];
    _composerDisplayed = NO;
}

- (void)reportControllerDidPressCancel:(SRReportViewController *)controller
{
    [self viewControllerDidPressCancel:controller];
}

#pragma mark - URL Connection Delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    [_loadingView removeFromSuperview];
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Report sent" message:@"Thank you for your help." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    if(SR_LOGS_ENABLED) {
        NSLog(@"[Shake Report] Report status:");
        NSLog(@"[Shake Report] HTTP Status Code: %ld", (long)response.statusCode);
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_loadingView removeFromSuperview];
    
    if(SR_LOGS_ENABLED) {
        NSLog(@"[Shake Report] Report status:");
        NSLog(@"[Shake Report] Error: %@", error);
    }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    [self displayProgressBarWithPercentage:(CGFloat)totalBytesWritten/(CGFloat)totalBytesExpectedToWrite];
}

@end
