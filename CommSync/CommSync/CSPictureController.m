//
//  CSPictureController.m
//  CommSync
//
//  Created by Anna Stavropoulos on 3/29/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSPictureController.h"

@interface CSPictureController ()

@property (nonatomic, assign) BOOL layedOut;

@end

@implementation CSPictureController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    
    self.pictureImage = [[UIImageView alloc] initWithImage:_taskImage];
    [self.zoomviewForImage addSubview:self.pictureImage];
    _pictureImage.userInteractionEnabled = YES;
    
    _layedOut = NO;

    //    [_pictureImage layoutIfNeeded];
    
    // configure image and scroll view for scrolling to extents of actual image
//    double widthScale = self.view.frame.size.width / _taskImage.size.width;
//    double heightScale = self.view.frame.size.height / _taskImage.size.height;
//    self.zoomviewForImage.minimumZoomScale = MAX(widthScale, heightScale);
//    self.zoomviewForImage.maximumZoomScale = MIN(1 / widthScale, 1 / heightScale) / [[UIScreen mainScreen] scale]; // scale to pixel resolution
//    self.zoomviewForImage.zoomScale = self.zoomviewForImage.minimumZoomScale;
    
//    self.zoomviewForImage.pictureImage = self.pictureImage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (UIView*) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _pictureImage;
}

- (IBAction)dismissController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) viewDidLayoutSubviews {
//    _zoomviewForImage.contentSize = _pictureImage.image.size;
//    _zoomviewForImage.contentSize = self.view.superview.frame.size;
    // 2. calculate the size of the image view
    [super viewDidLayoutSubviews];
    
    if(_layedOut)
        return;
    
    
    CGFloat scrollViewWidth = CGRectGetWidth(_zoomviewForImage.frame);
    CGFloat scrollViewHeight = CGRectGetHeight(_zoomviewForImage.frame);
    CGFloat imageViewWidth = CGRectGetWidth(_pictureImage.frame);
    CGFloat imageViewHeight = CGRectGetHeight(_pictureImage.frame);
    CGFloat widthRatio = scrollViewWidth / imageViewWidth;
    CGFloat heightRation = scrollViewHeight / imageViewHeight;
    CGFloat ratio = MIN(widthRatio, heightRation);
    CGRect newImageFrame = CGRectMake(0, 0, imageViewWidth * ratio, imageViewHeight * ratio);
    _pictureImage.frame = newImageFrame;
    _zoomviewForImage.contentSize = _pictureImage.frame.size;
    
    // 3. find the position of the imageView.
    CGFloat scrollViewCenterX = CGRectGetMidX(_zoomviewForImage.bounds);
    CGFloat scrollViewCenterY = CGRectGetMidY(_zoomviewForImage.bounds) + _zoomviewForImage.contentInset.top / 2 ;
    _pictureImage.center = CGPointMake(scrollViewCenterX, scrollViewCenterY);
    
    _layedOut = YES;

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
