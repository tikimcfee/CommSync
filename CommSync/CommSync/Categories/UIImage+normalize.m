//
//  UIImage+normalize.m
//  CommSync
//
//  Created by CommSync on 2/4/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "UIImage+normalize.h"

@implementation UIImage (fixOrientation)

- (void) normalizedImageWithCompletionBlock:(void (^)(UIImage*)) completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (self.imageOrientation == UIImageOrientationUp) {
            completion(self);
            return;
        }
        CGSize newSize = CGSizeMake(self.size.width / 2, self.size.height / 2);
//        UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
        UIGraphicsBeginImageContextWithOptions(newSize, NO, self.scale);
        [self drawInRect:(CGRect){0, 0, newSize}];
//        [self drawInRect:(CGRect){0, 0, self.size}];
        UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        completion(normalizedImage);
    });
}

@end
