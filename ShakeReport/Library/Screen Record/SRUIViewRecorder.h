//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "SRRecordable.h"

/*!
 Recorder for a UIView.
 */
@interface SRUIViewRecorder : NSObject <SRRecordable> {
  UIView *_view;
  CGSize _size;
    BOOL _keyboardUp;
    CGRect _keyboardFrame;
}

/*!
 Create UIView recorder of size.
 @param view View
 @param size Size
 */
- (id)initWithView:(UIView *)view size:(CGSize)size;

@end
