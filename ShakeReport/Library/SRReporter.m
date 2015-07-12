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
#import "SRUtils.h"
#import <MWWindow/MWWindow.h>

#define kCrashFlag @"kCrashFlag"
#define SR_LOGS_ENABLED NO

void uncaughtExceptionHandler(NSException *exception) {
    [[SRReporter reporter] onCrash:exception];
}


@interface SRReporter () <UIAlertViewDelegate>
@property (nonatomic,  strong) MFMailComposeViewController *mailController;
@property (nonatomic, strong) SRReportLoadingView *loadingView;
@property (nonatomic, assign) BOOL composerDisplayed;
@property (nonatomic, strong) MWWindow *composerWindow;
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

- (SRReport *)report {
    if (!_report) {
        _report = [SRReport new];
    }
    return _report;
}


#pragma mark Logs
- (void)startLog2File
{
    if (!isatty(STDERR_FILENO)) {
        NSString *logPath = [self.report logFilePath];
        [[NSFileManager defaultManager] removeItemAtPath:logPath error:nil];
        freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
    }
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
        SRImageEditorViewController *controller = [SRImageEditorViewController controllerWithImage:self.report.screenshot];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        if ([navController.navigationBar respondsToSelector:@selector(setTranslucent:)]) {
            [navController.navigationBar setTranslucent:YES];
        }

        if (_composerWindow) {
            [_composerWindow removeFromSuperview];
        }
        _composerWindow = [[MWWindow alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        _composerWindow.clipsToBounds = YES;
        [_composerWindow setPanGestureEnabled:NO];
        [_composerWindow setTapToCloseEnabled:NO];
        _composerWindow.windowLevel = UIWindowLevelStatusBar;
        _composerWindow.rootViewController = navController;
        [_composerWindow makeKeyAndVisible];
        [_composerWindow presentWindowAnimated:YES completion:^{
            
        }];
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

- (void)dismissComposer {
    if (_composerWindow) {
        __weak __typeof__(self) weakSelf = self;
        [_composerWindow dismissWindowAnimated:YES completion:^{
//            UIWindow *window = [[UIApplication sharedApplication].delegate window];
//            [window makeKeyWindow];
            weakSelf.composerDisplayed = NO;
        }];
    }
}

- (void)viewControllerDidPressCancel:(UIViewController *)controller
{
    [self setCrashFlag:NO];
    NSLog(@"window count count: %lu", [[UIApplication sharedApplication].windows count]);
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
    [crashString appendFormat:@"Exception: %@\n", exception];
    [crashString appendFormat:@"Name: %@\n", exception.name];
    [crashString appendFormat:@"Reason: %@\n", exception.reason];
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
        NSString *filePath = [self.report crashFilePath];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}

- (BOOL)crashFlag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:kCrashFlag];
}


#pragma mark Custom Information
- (void)setCustomInformationBlock:(NSString* (^)())block
{
    self.report.customInformationBlock = block;
}

#pragma mark Mail Composer
- (void)addAttachmentsToMailComposer:(MFMailComposeViewController *)mailComposer
{
    // Fetch Screenshot data
    UIImage *screenshot = [self.report screenshot];
    NSData *imageData = UIImageJPEGRepresentation(screenshot ,1.0);
    
    // Logs
    NSString *logs = [self.report logs];
    NSData* logsData = [logs dataUsingEncoding:NSUTF8StringEncoding];
    
    // View Hierarchy (Root=Window)
    NSString *viewDump = [self.report dumpedView];
    NSData* viewData = [viewDump dataUsingEncoding:NSUTF8StringEncoding];
    
    // Crash Report if we registered a crash
    NSString *crashReport = [self.report crashReport];
    if (!crashReport) {
        crashReport = @"No Crash";
    }
    NSData* crashData = [crashReport dataUsingEncoding:NSUTF8StringEncoding];
    
    // We attache all the information to the email
    [mailComposer addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"screenshot.jpeg"];
    [mailComposer addAttachmentData:logsData mimeType:@"text/plain" fileName:@"console.log"];
    [mailComposer addAttachmentData:viewData mimeType:@"text/plain" fileName:@"viewDump.log"];
    [mailComposer addAttachmentData:crashData mimeType:@"text/plain" fileName:@"crash.log"];
    NSString *message = [NSString stringWithFormat:@"Hey! I noticed something wrong with the app, here is some information.\nDevice model: %@\nOS version:%@", [self.report systemInformation][@"device_model"], [self.report systemInformation][@"os_version"]];
    [mailComposer setMessageBody:message isHTML:NO];
    
    //Custom Information
    NSString *additionalInformation = [self.report customInformation];
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
- (NSDictionary *)reportHTTPParams
{
    NSString *logs = [self.report logs];
    NSString *viewDump = [self.report dumpedView];
    NSString *crashReport = [self.report crashReport];
    NSMutableDictionary *reportParams = [NSMutableDictionary dictionary];
    reportParams[@"report[logs]"] = logs;
    reportParams[@"report[dumped_view]"] = viewDump;
    reportParams[@"report[title]"] = self.report.title;
    reportParams[@"report[message]"] = self.report.message;
    reportParams[@"report[device_model]"] = [self.report systemInformation][@"device_model"];
    reportParams[@"report[os_version]"] = [self.report systemInformation][@"os_version"];
    if (self.report.customInformationBlock) {
        NSString *customInfo = self.report.customInformation;
        if (customInfo && customInfo.length) {
            reportParams[@"report[custom_info]"] = customInfo;
        }
    }
    if (crashReport) {
        reportParams[@"report[crash_logs]"] = crashReport;
    }
    return reportParams;
}

- (NSMutableURLRequest *)reportHTTPRequest
{
    NSMutableDictionary *reportParams = [[self reportHTTPParams] mutableCopy];
    SRHTTPClient *httpClient = [[SRHTTPClient alloc] initWithBaseURL:_backendURL];
    if (_applicationToken) {
        [httpClient setDefaultHeader:@"X-APPLICATION-TOKEN" value:_applicationToken];
    }
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"api/reports.json" parameters:reportParams constructingBodyWithBlock: ^(id <SRMultipartFormData>formData) {
        UIImage *screenshot = [self.report screenshot];
        NSData *imageData = UIImageJPEGRepresentation(screenshot ,1.0);
        if (imageData) {
            [formData appendPartWithFileData:imageData name:@"report[screenshot_file]" fileName:@"screenshot.jpg" mimeType:@"image/jpeg"];
        }
        
        NSData *screenCapture;
        NSString *videoFile = self.report.screenCaptureVideoPath;
        if (videoFile && [SRUtils sr_exist:videoFile]) {
            screenCapture = [NSData dataWithContentsOfFile:videoFile];
            [formData appendPartWithFileData:screenCapture name:@"report[screen_capture]" fileName:@"screen_capture.mp4" mimeType:@"video/mp4"];
        }
        
    }];

    return request;
}

- (void)sendReport
{
    if (!_backendURL) {
        return;
    }
    NSMutableURLRequest *request = [self reportHTTPRequest];
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
    [self sendReport];
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
    _report = nil;
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
