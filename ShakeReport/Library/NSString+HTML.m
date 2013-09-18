//
//  NSString+HTML.m
//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "NSString+HTML.h"

@implementation NSString (HTML)


- (NSString*)toHTML
{
    NSString *htmlString = [self toHTMLSafe];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"\t" withString:@"&emsp;&emsp;&emsp;&emsp;"];
    return htmlString;
}

- (NSString *)toHTMLSafe {
    NSMutableString *encoded = [NSMutableString stringWithString:self];
    
    // @"&amp;"
    NSRange range = [self rangeOfString:@"&"];
    if (range.location != NSNotFound) {
        [encoded replaceOccurrencesOfString:@"&"
                                 withString:@"&amp;"
                                    options:NSLiteralSearch
                                      range:NSMakeRange(0, [encoded length])];
    }
    
    // @"&lt;"
    range = [self rangeOfString:@"<"];
    if (range.location != NSNotFound) {
        [encoded replaceOccurrencesOfString:@"<"
                                 withString:@"&lt;"
                                    options:NSLiteralSearch
                                      range:NSMakeRange(0, [encoded length])];
    }
    
    // @"&gt;"
    range = [self rangeOfString:@">"];
    if (range.location != NSNotFound) {
        [encoded replaceOccurrencesOfString:@">"
                                 withString:@"&gt;"
                                    options:NSLiteralSearch
                                      range:NSMakeRange(0, [encoded length])];
    }
    
    return encoded;
}

@end
