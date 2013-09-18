//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRRecordable.h"

/*!
 Recorder for the screen.
 
 @warning This uses a private API (UIGetScreenImage), and is not available in the simulator.
 */
@interface SRScreenRecorder : NSObject <SRRecordable> {
  void *_CRGetScreenImage; // Function pointer for UIGetScreenImage
  CGSize _size;
    UIWindow *_window;
    BOOL _keyboardUp;
    CGRect _keyboardFrame;

}
- (id)initWithWindow:(UIWindow *)window;

@end