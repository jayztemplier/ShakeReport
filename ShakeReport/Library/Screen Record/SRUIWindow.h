//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 Window for the recording.
 */
@interface SRUIWindow : NSObject {
}

/*!
 The current window instance.
 
 This is automatically set for most recent constructed CRUIWindow.
 */
+ (UIWindow *)window;

+ (void)setWindow:(UIWindow *)window;
@end
