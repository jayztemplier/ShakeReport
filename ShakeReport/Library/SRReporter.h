//
//  SRReporter.h
//  ShakeReport
//
//  Created by Jeremy Templier on 5/29/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIWindow+SRReporter.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "SRReportViewController.h"
#import "SRReport.h"



@interface SRReporter : NSObject <MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, SRReportViewControllerDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, copy) NSString *defaultEmailAddress;
@property (nonatomic, copy) NSURL *backendURL;
@property (nonatomic, copy) NSString *applicationToken;
@property (nonatomic, assign) BOOL lastSessionCrashed;
@property (nonatomic, assign) BOOL displayReportComposerWhenShakeDevice;
@property (nonatomic, assign) BOOL recordsCrashes;
@property (nonatomic, strong) SRReport *report;

+ (instancetype)reporter;

- (void)startListenerConnectedToBackendURL:(NSURL *)url;
- (void)startListener;

- (void)stopListener;

- (void)setCustomInformationBlock:(NSString* (^)())block;
- (void)setCrashFlag:(BOOL)flag;
/**
 Display one of the report composer (depends on the settings).
 Call this method if you want to link a button to the action of creating a new report.
 **/
- (void)displayReportComposer;
- (void)dismissComposer;

- (void)viewControllerDidPressCancel:(UIViewController *)viewController;
- (BOOL)canSendNewReport;
- (void)saveToCrashFile:(NSString *)crashContent;
- (void)onCrash:(NSException *)exception;


- (NSDictionary *)reportHTTPParams;
- (NSMutableURLRequest *)reportHTTPRequest;
- (void)sendReport;

- (void)addAttachmentsToMailComposer:(MFMailComposeViewController *)mailComposer;

@end
