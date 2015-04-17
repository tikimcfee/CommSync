//
//  CSTaskImageCollectionViewCell.h
//  CommSync
//
//  Created by Ivan Lugo on 4/13/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CSTaskImageCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *taskImageView;

- (void)configureCellWithImage:(UIImage*)taskImage;

@end
