//
//  ShakeReportTests.m
//  ShakeReportTests
//
//  Created by Jeremy Templier on 5/29/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "ShakeReportTests.h"
#import "SRReporter.h"

@implementation ShakeReportTests

- (void)setUp
{
    [super setUp];
    
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)testSingleton
{
    SRReporter *report = [SRReporter reporter];
    STAssertEquals(report, [SRReporter reporter], @"should always be the same object");
}

@end
