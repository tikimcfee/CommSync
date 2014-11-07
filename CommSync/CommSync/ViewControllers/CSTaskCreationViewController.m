//
//  CSTaskCreationViewController.m
//  CommSync
//
//  Created by Darin Doria on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSTaskCreationViewController.h"
#import "CSTask.h"
#import "AppDelegate.h"

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
    
    NSString* U = [NSString stringWithFormat:@"%c%c%c%c%c", arc4random_uniform(25)+65, arc4random_uniform(25)+65, arc4random_uniform(25)+65, arc4random_uniform(25)+65, arc4random_uniform(25)+65];
    NSString* D = [NSString stringWithFormat:@"%c%c%c%c%c", arc4random_uniform(25)+97, arc4random_uniform(25)+97, arc4random_uniform(25)+97, arc4random_uniform(25)+97, arc4random_uniform(25)+97];
    
    CSTask *task = [[CSTask alloc] initWithUUID:U andDeviceID:D];
    task.taskTitle = self.titleTextField.text;
    task.taskDescription = self.descriptionTextField.text;
    
    AppDelegate *d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [d.globalTaskManager insertTaskIntoList:task];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
