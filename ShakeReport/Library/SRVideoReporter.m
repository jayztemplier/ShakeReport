//
//  SRVideoReporter.m
//  ShakeReport
//
//  Created by Jeremy Templier on 9/22/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRVideoReporter.h"
#import "SRMethodSwizzler.h"
#import "CaptureRecord.h"
#import "SRUtils.h"
#import "SRHTTPClient.h"
#import <MessageUI/MFMailComposeViewController.h>

@implementation SRVideoReporter

- (id)init
{
    self = [super init];
    if (self) {
        if (self.lastSessionCrashed) {
            [self exportScreenCaptureForCrash];
        }
        [self removeOldVideoTemporaryFilesCrashFileIncluded:!self.lastSessionCrashed];
    }
    return self;
}

- (void)stopListener
{
    [super stopListener];
    [[SRRecorder sharedRecorder] stop:nil];
}

#pragma mark Screen Record
- (void)startScreenRecorder
{
    [self configureScreenCapture];
    [[SRRecorder sharedRecorder] start:nil];
}

- (void)startScreenRecorderWithMaxDurationPerVideo:(NSTimeInterval)timeInterval
{
    [self configureScreenCapture];
    [[SRRecorder sharedRecorder] startWithMaxVideoDuration:timeInterval error:nil];
}

- (void)configureScreenCapture
{
    _screenCaptureEnabled = YES;
    SwizzleInstanceMethod([UIWindow class], @selector(sendEvent:), @selector(SR_sendEvent:));
    [SRUIWindow setWindow:[[UIApplication sharedApplication].delegate window]];
    [[SRRecorder sharedRecorder] setOptions: CRRecorderOptionUserAudioRecording | CRRecorderOptionTouchRecording];
}

- (void)removeOldVideoTemporaryFilesCrashFileIncluded:(BOOL)deleteCrashFiles
{
    [SRUtils sr_temporaryFile:CRFileChunk1 deleteIfExists:YES error:nil];
    [SRUtils sr_temporaryFile:CRFileChunk2 deleteIfExists:YES error:nil];
    if (deleteCrashFiles) {
        [SRUtils sr_temporaryFile:CRFileCrash1 deleteIfExists:YES error:nil];
        [SRUtils sr_temporaryFile:CRFileCrash2 deleteIfExists:YES error:nil];
    }
}

- (void)exportScreenCaptureForCrash
{
    [SRUtils sr_copyTemporaryFile:CRFileChunk1 toFile:CRFileCrash1 error:nil];
    [SRUtils sr_copyTemporaryFile:CRFileChunk2 toFile:CRFileCrash2 error:nil];
}

#pragma mark Report
- (void)sendNewReport
{
    if (![self canSendNewReport]) {
        return;
    }
    if (_screenCaptureEnabled) {
        if ([[SRRecorder sharedRecorder] isRecording]) {
            [[SRRecorder sharedRecorder] stop:nil];
            [[SRRecorder sharedRecorder] saveVideoToAlbumWithName:@"Shake Report" resultBlock:^(NSURL *URL) {
                
            } failureBlock:^(NSError *error) {
                
            }];
        }
        [[SRRecorder sharedRecorder] mergeVideos];
    }
    [super sendNewReport];
}

- (void)onCrash:(NSException *)exception
{
    [super onCrash:exception];
    if (_screenCaptureEnabled) {
        [[SRRecorder sharedRecorder] stop:nil];
    }
}

#pragma mark - URL Connection 
- (NSMutableURLRequest *)requestForHTTPReportWithTitle:(NSString *)title andMessage:(NSString *)message
{
    if (!_screenCaptureEnabled) {
        return [super requestForHTTPReportWithTitle:title andMessage:message];
    }
    NSMutableDictionary *reportParams = [[self paramsForHTTPReportWithTitle:title andMessage:message] mutableCopy];
    NSData *screenCapture;
    NSString *videoFile = [[SRRecorder sharedRecorder] screenCaptureVideoPath];
    if (videoFile && [SRUtils sr_exist:videoFile]) {
        screenCapture = [NSData dataWithContentsOfFile:videoFile];
    }
    SRHTTPClient *httpClient = [[SRHTTPClient alloc] initWithBaseURL:self.backendURL];
    
    if (self.username && self.password) {
        [httpClient setAuthorizationHeaderWithUsername:[self username] password:[self password]];
    }
    
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/reports.json" parameters:reportParams constructingBodyWithBlock: ^(id <SRMultipartFormData>formData) {
        [formData appendPartWithFileData:screenCapture name:@"report[screen_capture]" fileName:@"screen_capture.mp4" mimeType:@"video/mp4"];
    }];
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    [super connection:connection didReceiveResponse:response];
    if (_screenCaptureEnabled) {
        [self removeOldVideoTemporaryFilesCrashFileIncluded:YES];
        [self startScreenRecorder];
    }
}

#pragma mark - Mail Attachments
- (void)addAttachmentsToMailComposer:(MFMailComposeViewController *)mailComposer
{
    [super addAttachmentsToMailComposer:mailComposer];
    
    if (_screenCaptureEnabled) {
        NSString *videoFile = [[SRRecorder sharedRecorder] screenCaptureVideoPath];
        if (videoFile && [SRUtils sr_exist:videoFile]) {
            NSData *screenCapture = [NSData dataWithContentsOfFile:videoFile];
            [mailComposer addAttachmentData:screenCapture mimeType:@"video/MP4" fileName:@"screen_capture.mp4"];
        }
    }
    
}
@end
