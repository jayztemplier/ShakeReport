//
//  SRReporter.h
//  ShakeReport
//
//  Created by Jeremy Templier on 5/29/13.
//  Copyright (c) 2013 Jayztemplier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIWindow+SRReporter.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

typedef NSString* (^SRCustomInformationBlock)();


@interface SRReporter : NSObject <MFMailComposeViewControllerDelegate, UINavigationControllerDelegate>

@property (readwrite, nonatomic, copy) SRCustomInformationBlock customInformationBlock;
@property (nonatomic, copy) NSString *defaultEmailAddress;
@property (nonatomic, copy) NSURL *backendURL;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *projectKey;
@property (nonatomic, copy) NSString *jiraDefaultAssignedUser;

+ (id)reporter;
- (void)startListenerConnectedToBackendURL:(NSURL *)url;
- (void)startListenerWithJIRAIntegrationAtURL:(NSURL *)jiraURL andUsername:(NSString *)username password:(NSString *)password projectKey:(NSString *)projectKey andDefaultAssignedUser:(NSString *)user;
- (void)startListener;

- (void)setCustomInformationBlock:(NSString* (^)())block;

- (void)sendNewReport;
- (void)saveToCrashFile:(NSString *)crashContent;
@end
