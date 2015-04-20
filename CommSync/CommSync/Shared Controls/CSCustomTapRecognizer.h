//
//  CSCustomTapRecognizer.h
//  CommSync
//
//  Created by Ivan Lugo on 4/20/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CSCustomTapListenerDelegate <NSObject>
- (void)handleSuccessfulTouchEvent:(UITapGestureRecognizer*)recognizer;
@end

@interface CSCustomTapRecognizer : UITapGestureRecognizer

@property (nonatomic, assign) CGRect frameToDetect;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, weak) id <CSCustomTapListenerDelegate> tapDelegate;

@end

