//
//  SRReporter+JIRA.m
//  ShakeReport
//
//  Created by jeremy Templier on 27/06/2013.
//  Copyright (c) 2013 Jayztemplier. All rights reserved.
//

#import "SRJIRAReporter.h"
#import "SRReporter+Private.h"

@interface SRJIRAReporter ()
@property (nonatomic, assign) BOOL useJIRAIntegration;
@end

@implementation SRJIRAReporter


- (void)startListenerWithJIRAIntegrationAtURL:(NSURL *)jiraURL andUsername:(NSString *)username password:(NSString *)password projectKey:(NSString *)projectKey andDefaultAssignedUser:(NSString *)user
{
    self.backendURL = jiraURL;
    self.username = username;
    self.password = password;
    _projectKey = projectKey;
    _jiraDefaultAssignedUser = user;
    _useJIRAIntegration = (username && password && jiraURL && projectKey);
    [self startListener];
}

#pragma mark Report
- (void)sendNewReport
{
    if (self.useJIRAIntegration) {
        [self sendToJira];
    } else {
        [super sendNewReport];
    }
}


- (void)sendToJira
{
    NSURL *issueURL = [NSURL URLWithString:@"/rest/api/2/issue" relativeToURL:self.backendURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:issueURL];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:@"nocheck" forHTTPHeaderField:@"X-Atlassian-Token"];
    [request setHTTPMethod:@"POST"];
    NSString *paramsString = [[self jiraParamsDictionary] JSONString];
    NSData *requestData = [NSData dataWithBytes:[paramsString UTF8String] length:[paramsString length]];
    [request setHTTPBody:requestData];
    
    // Authentication
    [self setAuthenticationParamsToRequest:request];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Report sent"
                                                            message:@"Thank you for your help."
                                                           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        } else {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"An error occured"
                                                            message:[NSString
                                                                     stringWithFormat:@"We are not able to send the report (error %d). Please contact the engineering team.", httpResponse.statusCode]
                                                           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        if(SR_LOGS_ENABLED) {
            NSLog(@"[Shake Report] Report status:");
            NSLog(@"[Shake Report] HTTP Status Code: %d", httpResponse.statusCode);
            if (data) {
                NSLog(@"[Shake Report] Response Body: %@", [data objectFromJSONData]);
            }
            NSLog(@"[Shake Report] Error: %@", error);
        }
    }];
}

- (NSDictionary *)jiraParamsDictionary
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    NSString *description = [NSString stringWithFormat:@"Bundle Version: %@", bundleVersion];
    [params setValue:@{@"key": _projectKey} forKey:@"project"];
    [params setValue:@"New bug reported from the Shake Reporter" forKey:@"summary"];
    [params setValue:description forKey:@"description"];
    [params setValue:(_jiraDefaultAssignedUser ? _jiraDefaultAssignedUser : @"") forKey:@"assignee"];
    [params setValue:@{@"name": @"Bug"} forKey:@"issuetype"];
    
    return @{@"fields": params};
}

@end
