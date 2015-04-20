//
//  CSCustomTapRecognizer.m
//  CommSync
//
//  Created by Ivan Lugo on 4/20/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSCustomTapRecognizer.h"

#define hitBox 30

@implementation CSCustomTapRecognizer

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event {
    
//    NSLog(@"In [%@]: %f, %f", self.name, self.view.frame.origin.x, self.view.frame.origin.y);
//    NSLog(@"FOR: %f, %f :: %f, %f", self.frameToDetect.origin.x, self.frameToDetect.origin.y,
//                                      self.frameToDetect.size.width, self.frameToDetect.size.height);
    
    CGRect biggerTouch = CGRectMake(CGRectGetMinX(_frameToDetect) - hitBox,
                                    CGRectGetMinY(_frameToDetect) - hitBox,
                                    CGRectGetWidth(_frameToDetect) + hitBox,
                                    CGRectGetHeight(_frameToDetect) + hitBox);

    biggerTouch = [self.view convertRect:biggerTouch toView:nil];
    CGRect someRect = [self.view convertRect:_frameToDetect toView:nil];
    
    NSLog(@"BIGGER: %f, %f :: %f, %f", biggerTouch.origin.x, biggerTouch.origin.y,
          biggerTouch.size.width, biggerTouch.size.height);
    
    for (UITouch* touch in touches) {
        // tap location in the window
        CGPoint loc = [touch locationInView:nil];
        NSLog(@"%f, %f", loc.x, loc.y);
        
        if (CGRectContainsPoint(biggerTouch, loc)) {
            [self.tapDelegate handleSuccessfulTouchEvent:self];
        }
    }
}

@end
