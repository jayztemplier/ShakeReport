//
//  SRReporter+Private.h
//  ShakeReport
//
//  Created by jeremy Templier on 27/06/2013.
//  Copyright (c) 2013 Jayztemplier. All rights reserved.
//

#ifndef ShakeReport_SRReporter_Private_h
#define ShakeReport_SRReporter_Private_h

#define SR_LOGS_ENABLED NO

@interface SRReporter (Private)
- (void)setAuthenticationParamsToRequest:(NSMutableURLRequest*)request;
@end

#endif
