//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "SRUIWindow.h"
#import "SRDefines.h"
#import "SRRecorder.h"

@implementation SRUIWindow

static UIWindow *gWindow = NULL;

+ (void)setWindow:(UIWindow *)window {
  gWindow = window;
}

+ (UIWindow *)window {
  return gWindow;
}
@end

