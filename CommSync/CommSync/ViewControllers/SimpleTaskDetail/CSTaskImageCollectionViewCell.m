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
    
}
//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code
////        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"CMFGalleryCell" owner:self options:nil];
////        
////        if ([arrayOfViews count] < 1) {
////            return nil;
////        }
////        
////        if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UICollectionViewCell class]]) {
////            return nil;
////        }
////        
////        self = [arrayOfViews objectAtIndex:0];
//    }
//    
//    return self;
//}

- (void)configureCellWithImage:(UIImage*)taskImage {
    [_taskImageView setImage:taskImage];
    [_taskImageView setContentMode:UIViewContentModeScaleAspectFill];
}

@end
