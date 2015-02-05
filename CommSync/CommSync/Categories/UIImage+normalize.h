//
//  UIImage+normalize.h
//  CommSync
//
//  Created by CommSync on 2/4/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (fixOrientation)

- (void)normalizedImageWithCompletionBlock:(void (^)(UIImage*)) completion;

@end
