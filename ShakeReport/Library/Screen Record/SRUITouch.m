//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRUITouch.h"

@implementation SRUITouch

- (id)initWithPoint:(CGPoint)point {
  if ((self = [super init])) {
    _point = point;
    _time = [NSDate timeIntervalSinceReferenceDate];
  }
  return self;
}

@end
