//
//  SRReporter+JIRA.h
//  ShakeReport
//
//  Created by jeremy Templier on 27/06/2013.
//  Copyright (c) 2013 Jayztemplier. All rights reserved.
//

#import "SRReporter.h"

@interface SRJIRAReporter : SRReporter

@property (nonatomic, copy) NSString *projectKey;
@property (nonatomic, copy) NSString *jiraDefaultAssignedUser;

- (void)startListenerWithJIRAIntegrationAtURL:(NSURL *)jiraURL andUsername:(NSString *)username password:(NSString *)password projectKey:(NSString *)projectKey andDefaultAssignedUser:(NSString *)user;
@end
