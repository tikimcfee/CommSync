//
//  CSTaskCreationViewController.m
//  CommSync
//
//  Created by Darin Doria on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSTaskCreationViewController.h"
#import "CSTask.h"

@interface CSTaskCreationViewController()
@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet UITextView *descriptionTextField;

@end


@implementation CSTaskCreationViewController

- (IBAction)tapGesture:(id)sender {
    [_titleTextField resignFirstResponder];
    [_descriptionTextField resignFirstResponder];
}

- (IBAction)closeViewWithoutSaving:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];

}
- (IBAction)closeViewAndSave:(id)sender {
    
    CSTask *task = [[CSTask alloc] initWithUUID:@"UUID" andDeviceID:@"deviceID"];
    
    
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
