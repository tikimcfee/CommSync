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
@property (nonatomic, strong) UITapGestureRecognizer* dismissTap;

@end

@implementation CSPictureController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    self.pictureImage = [[UIImageView alloc] initWithImage:_taskImage];
    [self.zoomviewForImage addSubview:self.pictureImage];
    _pictureImage.userInteractionEnabled = YES;
    
    _dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissController:)];
    _dismissTap.numberOfTapsRequired = 1;
    _dismissTap.numberOfTouchesRequired = 1;
    [_pictureImage addGestureRecognizer:_dismissTap];
    
    _layedOut = NO;
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

- (void)dismissController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) viewDidLayoutSubviews {
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

@end
