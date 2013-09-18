//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>

@interface SRUITouch : NSObject

@property CGPoint point;
@property NSTimeInterval time;

- (id)initWithPoint:(CGPoint)point;

@end
