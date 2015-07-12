//
//  SRReport+Network.m
//  ShakeReport
//
//  Created by Jeremy Templier on 04/07/15.
//  Copyright (c) 2015 Jayztemplier. All rights reserved.
//

#import "SRReport+Network.h"

@implementation SRReport (Network)

- (NSDictionary *)reportHTTPParams
{
    NSString *logs = [self logs];
    NSString *viewDump = [self dumpedView];
//    NSString *crashReport = [self crashReport];
    NSMutableDictionary *reportParams = [NSMutableDictionary dictionary];
    reportParams[@"report[logs]"] = logs;
    reportParams[@"report[dumped_view]"] = viewDump;
    reportParams[@"report[title]"] = self.title;
    reportParams[@"report[message]"] = self.message;
    reportParams[@"report[device_model]"] = [self systemInformation][@"device_model"];
    reportParams[@"report[os_version]"] = [self systemInformation][@"os_version"];
    if (self.customInformationBlock) {
        NSString *customInfo = [self customInformation];
        if (customInfo && customInfo.length) {
            reportParams[@"report[custom_info]"] = customInfo;
        }
    }
//    if (crashReport) {
//        reportParams[@"report[crash_logs]"] = crashReport;
//    }
    return reportParams;
}


@end
