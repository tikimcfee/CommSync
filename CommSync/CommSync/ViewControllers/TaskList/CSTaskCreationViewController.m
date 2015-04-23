//
//  CSTaskCreationViewController.m
//  CommSync
//
//  Created by Darin Doria on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//


#import "CSTaskCreationViewController.h"

// Data models
#import <Realm/Realm.h>
#import "CSTaskRealmModel.h"
#import "CSCommentRealmModel.h"
#import "AppDelegate.h"
#import "CSSessionManager.h"

// Categories
#import "UIImage+normalize.h"

// UI
#import "SZTextView.h"
#import "CSAudioPlotViewController.h"
#import "CSPictureController.h"
#import "IonIcons.h"
#import "UIColor+FlatColors.h"
#import "UINavigationBar+CommSyncStyle.h"
#import "CSTaskImageCollectionViewCell.h"
#import "CSTaskMediaCreationViewController.h"

// Data transmission
#import "CSSessionDataAnalyzer.h"



@interface CSTaskCreationViewController() 

// Main view
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet SZTextView *descriptionTextField;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@property (strong, nonatomic) IBOutlet UIButton *lowPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *mediumPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *highPriorityButton;

@property (strong, nonatomic) IBOutlet UIButton *addTaskImageButton;
@property (strong, nonatomic) IBOutlet UIButton *assignButton;
@property (strong, nonatomic) IBOutlet UILabel *assignedLabel;

// Image picker
@property (strong, nonatomic) UIImagePickerController* imagePicker;
@property (strong, nonatomic) IBOutlet UICollectionView *taskImageCollection;
@property (strong, nonatomic) NSMutableArray* taskImages;


// VC for audio recording
@property (weak, nonatomic) CSAudioPlotViewController* audioRecorder;

// Realm
@property (weak, nonatomic) RLMRealm* realm;
@property (strong, nonatomic) CSTaskRealmModel* pendingTask;

//manager
@property (strong, nonatomic) CSSessionManager *sessionManager;

@end


@implementation CSTaskCreationViewController

#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _sessionManager = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).globalSessionManager;
    
    // init properties
    self.taskImages = [NSMutableArray new];
    [self sharedInit];
    
    // disable next button
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // focus on title text field immediately
    [self.titleTextField becomeFirstResponder];
    
    // set styles
    [self configureInitialStyling];
    
    /* -- Notifications -- */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChange:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"kCSTaskMediaCreationSegue"]) {
        
        CSTaskMediaCreationViewController *vc = segue.destinationViewController;
        // get current pending task values
        self.pendingTask.taskTitle = self.titleTextField.text;
        self.pendingTask.taskDescription = self.descriptionTextField.text;

        [vc configureWithPendingTask:self.pendingTask];
        
    } else if ([segue.identifier isEqualToString:@"kAssignTaskSegue"]) {
        
        CSUserSelectionViewController *vc = segue.destinationViewController;
        vc.saveDelegate = self;
        
    }
}

- (void)sharedInit
{
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
    _pendingTask.assignedID = @"";
    _pendingTask.deviceID = D;
    _pendingTask.concatenatedID = [NSString stringWithFormat:@"%@%@", U, D];
    
    self.descriptionTextField.placeholder = @"Enter description here...";
}

#pragma mark - Helper Methods
- (void)configureInitialStyling {
    
    /* -- Set Styles -- */
    self.view.backgroundColor = [UIColor flatCloudsColor];
    self.descriptionTextField.backgroundColor = [UIColor flatCloudsColor];
    self.lowPriorityButton.backgroundColor = [UIColor flatBelizeHoleColor];
    self.mediumPriorityButton.backgroundColor = [UIColor flatOrangeColor];
    self.highPriorityButton.backgroundColor = [UIColor flatPomegranateColor];
    self.lowPriorityButton.layer.cornerRadius = self.lowPriorityButton.frame.size.width / 2;
    self.mediumPriorityButton.layer.cornerRadius = self.mediumPriorityButton.frame.size.width / 2;
    self.highPriorityButton.layer.cornerRadius = self.highPriorityButton.frame.size.width / 2;
    [self.lowPriorityButton setImage:[IonIcons imageWithIcon:ion_ios_checkmark_empty size:50.0f color:[UIColor whiteColor]] forState:UIControlStateNormal];

    
    // configure camera button style
    self.addTaskImageButton.layer.cornerRadius = 22.0f;
    self.addTaskImageButton.backgroundColor = [UIColor flatWetAsphaltColor];
    [self.addTaskImageButton setImage:[IonIcons imageWithIcon:ion_ios_camera size:35.0f color:[UIColor flatCloudsColor]] forState:UIControlStateNormal];
    
    // configure assign button style
    self.assignButton.tintColor = [UIColor flatWetAsphaltColor];
    [self.assignButton setImage:[IonIcons imageWithIcon:ion_ios_personadd_outline size:35.0f color:[UIColor flatWetAsphaltColor]] forState:UIControlStateNormal];
    [self.assignButton setImage:[IonIcons imageWithIcon:ion_ios_personadd size:35.0f color:[UIColor flatWetAsphaltColor]] forState:UIControlStateHighlighted];
    
    // set navbar style
    [self.navigationController.navigationBar setupCommSyncStyle];
}

#pragma mark - Notification Methods
- (void)textFieldDidChange:(NSNotification*)notification {
    self.navigationItem.rightBarButtonItem.enabled = (self.titleTextField.hasText && self.descriptionTextField.hasText) ? YES : NO;
}

#pragma mark - IBActions
- (IBAction)priorityButtonTapped:(id)sender {
    
    if (sender == self.lowPriorityButton) {
        self.pendingTask.taskPriority = CSTaskPriorityLow;
        [self.lowPriorityButton setImage:[IonIcons imageWithIcon:ion_ios_checkmark_empty size:50.0f color:[UIColor whiteColor]] forState:UIControlStateNormal];
        [self.mediumPriorityButton setImage:nil forState:UIControlStateNormal];
        [self.highPriorityButton setImage:nil forState:UIControlStateNormal];
        
    } else if (sender == self.mediumPriorityButton) {
        self.pendingTask.taskPriority = CSTaskPriorityMedium;
        [self.mediumPriorityButton setImage:[IonIcons imageWithIcon:ion_ios_checkmark_empty size:50.0f color:[UIColor whiteColor]] forState:UIControlStateNormal];
        [self.lowPriorityButton setImage:nil forState:UIControlStateNormal];
        [self.highPriorityButton setImage:nil forState:UIControlStateNormal];

    } else {
        self.pendingTask.taskPriority = CSTaskPriorityHigh;
        [self.highPriorityButton setImage:[IonIcons imageWithIcon:ion_ios_checkmark_empty size:50.0f color:[UIColor whiteColor]] forState:UIControlStateNormal];
        [self.lowPriorityButton setImage:nil forState:UIControlStateNormal];
        [self.mediumPriorityButton setImage:nil forState:UIControlStateNormal];

    }
}

- (IBAction)tapGesture:(id)sender {
    [_titleTextField resignFirstResponder];
    [_descriptionTextField resignFirstResponder];
}

- (IBAction)closeViewWithoutSaving:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.titleTextField resignFirstResponder];
    [self.descriptionTextField resignFirstResponder];
}

#pragma mark - UITextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [self.descriptionTextField becomeFirstResponder];
    [textField resignFirstResponder];
    
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark - CSUserSelectionViewController Delegate
- (void)assignUser:(NSString *)personID {
    if (personID) {
        self.pendingTask.assignedID = personID;
//        [self.assignButton.titleLabel setText:[CSUserRealmModel objectInRealm:[CSRealmFactory peerHistoryRealm] forPrimaryKey:personID].displayName];
        self.assignedLabel.text = [NSString stringWithFormat:@"Assigned to %@", [CSUserRealmModel objectInRealm:[CSRealmFactory peerHistoryRealm] forPrimaryKey:personID].displayName];
    } else {
        self.assignedLabel.text = @"Unassigned";
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
