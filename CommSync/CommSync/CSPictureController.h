//
//  CSPictureController.h
//  CommSync
//
//  Created by Anna Stavropoulos on 3/29/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CSPictureController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) UIImage* taskImage;
@property (strong, nonatomic) UIImageView *pictureImage;
@property (strong, nonatomic) IBOutlet UIScrollView *zoomviewForImage;


@end
