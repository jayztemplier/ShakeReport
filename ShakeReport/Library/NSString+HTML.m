//
//  NSString+HTML.m
//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jayztemplier. All rights reserved.
//

#import "NSString+HTML.h"

@implementation NSString (HTML)


- (NSString*)toHTML
{
    NSString *htmlString = [self stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"\t" withString:@"&emsp;&emsp;&emsp;&emsp;"];
    return htmlString;
}

@end
