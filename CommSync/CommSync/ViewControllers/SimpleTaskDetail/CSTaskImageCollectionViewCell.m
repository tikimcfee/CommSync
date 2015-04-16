//
//  CSTaskImageCollectionViewCell.m
//  CommSync
//
//  Created by Ivan Lugo on 4/13/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskImageCollectionViewCell.h"

@implementation CSTaskImageCollectionViewCell


- (void) awakeFromNib {
    [super awakeFromNib];
    
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.contentView.translatesAutoresizingMaskIntoConstraints = YES;
}

- (void)configureCellWithImage:(UIImage*)taskImage {
    
    
    [_taskImageView setImage:taskImage];
    [_taskImageView setContentMode:UIViewContentModeScaleAspectFill];
}

@end
