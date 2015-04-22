//
//  CSTaskMediaCreationViewController.h
//  CommSync
//
//  Created by Student on 4/22/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"

@interface CSTaskMediaCreationViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
- (void) configureWithPendingTask:(CSTaskRealmModel*)task;
@end
