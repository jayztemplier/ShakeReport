//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRScreenRecorder.h"

#import <UIKit/UIKit.h>
#import "SRDefines.h"
#import "SRUtils.h"
#include <dlfcn.h>
#include <stdio.h>
#define UIKITPATH "/System/Library/Framework/UIKit.framework/UIKit"

@implementation SRScreenRecorder

- (id)initWithWindow:(UIWindow *)window {
  if ((self = [super init])) {
      _window = window;
    void *UIKit = dlopen(UIKITPATH, RTLD_LAZY);
    NSString *methodName = [SRUtils sr_rot13:@"HVTrgFperraVzntr"]; // UIGetScreenImage
    _CRGetScreenImage = dlsym(UIKit, [methodName UTF8String]);
    dlclose(UIKit);
    
    _size = [UIScreen mainScreen].bounds.size;
      [self registerForKeyboardNotifications];
  }
  return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)renderInContext:(CGContextRef)context videoSize:(CGSize)videoSize {
  if (!_CRGetScreenImage) return;
  CGImageRef (*CRGetScreenImage)() = _CRGetScreenImage;
  CGImageRef image = CRGetScreenImage();
  CGContextDrawImage(context, CGRectMake(0, 0, _size.width, _size.height), image);
  CGImageRelease(image);
    if (_keyboardUp) {
        UIView *firstResponderView = [self findFirstResponderInView:(UIView *)_window];
        if (firstResponderView && [firstResponderView isKindOfClass:[UITextField class]] && ((UITextField *)firstResponderView).isSecureTextEntry) {
            CGRect f = firstResponderView.frame;
            CGPoint origin = [firstResponderView.superview convertPoint:f.origin toView:nil];
            f.origin = CGPointMake(origin.x, CGRectGetHeight(_window.bounds) - origin.y - CGRectGetHeight(f));
            UIBezierPath *hideField = [UIBezierPath bezierPathWithRect:f];
            CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
            CGContextAddPath(context, hideField.CGPath);
            CGContextFillPath(context);
            UIBezierPath *hideKeyboard = [UIBezierPath bezierPathWithRect:_keyboardFrame];
            CGContextAddPath(context, hideKeyboard.CGPath);
            CGContextFillPath(context);
        }
    }

}

- (CGSize)size {
  return CGSizeMake(_size.width, _size.height);
}


- (UIView *)findFirstResponderInView:(UIView *)view
{
    if (view.isFirstResponder) {
        return view;
    }
    
    for (UIView *subView in view.subviews) {
        UIView *firstResponder = [self findFirstResponderInView:subView];
        
        if (firstResponder != nil) {
            return firstResponder;
        }
    }
    
    return nil;
}

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    _keyboardFrame = CGRectMake(0, 0, CGRectGetWidth(_window.bounds), kbSize.height);
    _keyboardUp = YES;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    _keyboardUp = NO;
}

@end
