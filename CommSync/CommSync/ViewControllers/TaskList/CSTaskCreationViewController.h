//
//  CSTaskCreationViewController.h
//  CommSync
//
//  Created by Darin Doria on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"
#import "CSTaskDetailViewController.h"

@interface CSTaskCreationViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;

@property (strong, nonatomic) CSTaskDetailViewController *taskScreen;
@end