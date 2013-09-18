//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRUIViewRecorder.h"
#import <QuartzCore/QuartzCore.h>

@implementation SRUIViewRecorder

- (id)initWithView:(UIView *)view size:(CGSize)size {
    if ((self = [super init])) {
        _view = view;
        _size = size;
        [self registerForKeyboardNotifications];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGSize)size {
  return _size;
}

- (void)renderInContext:(CGContextRef)context videoSize:(CGSize)videoSize {
    CGContextSaveGState(context);
    CGContextConcatCTM(context, CGAffineTransformMake(1, 0, 0, -1, 0, _size.height));
    CGContextTranslateCTM(context, _view.center.x, _view.center.y);
    CGContextConcatCTM(context,  _view.transform);
    CGContextTranslateCTM(context, -_view.bounds.size.width * _view.layer.anchorPoint.x, -_view.bounds.size.height * _view.layer.anchorPoint.y);
    [_view.layer renderInContext:context];
    UIView *firstResponderView = [self findFirstResponderInView:_view];
    if (firstResponderView && [firstResponderView isKindOfClass:[UITextField class]] && ((UITextField *)firstResponderView).isSecureTextEntry) {
        UIBezierPath *hideField = [UIBezierPath bezierPathWithRect:firstResponderView.frame];
        CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
        CGContextAddPath(context, hideField.CGPath);
        CGContextFillPath(context);
        if (_keyboardUp) {
            UIBezierPath *hideKeyboard = [UIBezierPath bezierPathWithRect:_keyboardFrame];
            CGContextAddPath(context, hideKeyboard.CGPath);
            CGContextFillPath(context);
        }
    }
    CGContextRestoreGState(context);
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
    _keyboardFrame = CGRectMake(0, CGRectGetHeight(_view.bounds) - kbSize.height, CGRectGetWidth(_view.bounds), kbSize.height);
    _keyboardUp = YES;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    _keyboardUp = NO;
}
@end
