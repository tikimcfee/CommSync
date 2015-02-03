//
//  CSTaskCreationViewController.m
//  CommSync
//
//  Created by Darin Doria on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSTaskCreationViewController.h"
#import "CSTaskRealmModel.h"
#import "AppDelegate.h"

#import <Realm/Realm.h>

@interface CSTaskCreationViewController()
@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet UITextView *descriptionTextField;
@property (strong, nonatomic) IBOutlet UIButton *lowPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *mediumPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *highPriorityButton;

@property (weak, nonatomic) RLMRealm* realm;
@property (strong, nonatomic) CSTaskRealmModel *pendingTask;
@end


@implementation CSTaskCreationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString* U = [NSString stringWithFormat:@"%c%c%c%c%c",
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65];
    NSString* D = [NSString stringWithFormat:@"%c%c%c%c%c",
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97];
    
    _realm = [RLMRealm defaultRealm];
    
    self.pendingTask = [[CSTaskRealmModel alloc] init];
    _pendingTask.UUID = U;
    _pendingTask.deviceID = D;
    _pendingTask.concatenatedID = [NSString stringWithFormat:@"%@%@", U, D];
}


#pragma mark - IBActions

- (IBAction)priorityButtonTapped:(id)sender {
    
    if (sender == self.lowPriorityButton)
    {
        self.pendingTask.taskPriority = CSTaskPriorityLow;
    }
    else if (sender == self.mediumPriorityButton)
    {
        self.pendingTask.taskPriority = CSTaskPriorityMedium;
    }
    else
    {
        self.pendingTask.taskPriority = CSTaskPriorityHigh;
    }
}

- (IBAction)tapGesture:(id)sender {
    [_titleTextField resignFirstResponder];
    [_descriptionTextField resignFirstResponder];
}

- (IBAction)closeViewWithoutSaving:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];

}
- (IBAction)closeViewAndSave:(id)sender {
    
    
    self.pendingTask.taskTitle = self.titleTextField.text;
    self.pendingTask.taskDescription = self.descriptionTextField.text;
    
    [_realm beginWriteTransaction];
    [_realm addObject:self.pendingTask];
    [_realm commitWriteTransaction];
    
    AppDelegate *d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [d.globalSessionManager sendDataPacketToPeers:[NSKeyedArchiver archivedDataWithRootObject:self.pendingTask]];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
