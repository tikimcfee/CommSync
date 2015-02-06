//
//  CSTaskDetailViewController.m
//  CommSync
//
//  Created by Darin Doria on 1/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskDetailViewController.h"

@interface CSTaskDetailViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *taskImage;

@end

@implementation CSTaskDetailViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.titleLabel.text = self.sourceTask.taskTitle;
    self.descriptionLabel.text = self.sourceTask.taskDescription;
    
    [self.sourceTask getAllImagesForTaskWithCompletionBlock:^void(BOOL didFinish) {
        if(didFinish) {
            [self setImagesFromTask];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


# pragma mark - Callbacks and UI State
- (void)setImagesFromTask {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.sourceTask.TRANSIENT_taskImages.count > 0) {
            UIImage* img = [self.sourceTask.TRANSIENT_taskImages objectAtIndex:0];
            self.taskImage.image = img;
        }
    });
}


@end
