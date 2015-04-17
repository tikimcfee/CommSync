//
//  CSInsetTextField.m
//  CommSync
//
//  Created by Ivan Lugo on 4/16/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSInsetTextField.h"

@interface CSInsetTextField()

@property (nonatomic, assign) BOOL calculated;
@property (nonatomic, assign) CGRect insetRect;

@end

@implementation CSInsetTextField

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (CGRect)textRectForBounds:(CGRect)bounds {
    [super textRectForBounds:bounds];
    if (_calculated) {
        return _insetRect;
    }
    
    _insetRect = CGRectInset(bounds, 4, 4);
    return _insetRect;
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    [super editingRectForBounds:bounds];
    if (_calculated) {
        return _insetRect;
    }
    
    _insetRect = CGRectInset(bounds, 4, 4);
    return _insetRect;
}

@end
