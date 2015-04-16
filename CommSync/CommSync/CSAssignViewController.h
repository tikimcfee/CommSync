//
//  CSAssignViewController.h
//  CommSync
//
//  Created by Anna Stavropoulos on 4/4/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CSSessionManager.h"
#import "CSTaskRealmModel.h"
#import "CSUserRealmModel.h"
#import <Realm/Realm.h>


@interface CSAssignViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIPickerView *spinner;
@property (weak, nonatomic) IBOutlet NSString *tempAssignment;
@property (weak, nonatomic) IBOutlet UILabel *assignmentLabel;
@property (weak, nonatomic) IBOutlet CSTaskRealmModel *sourceTask;
- (IBAction)cancel:(id)sender;
- (IBAction)assign:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *tagLabel;
@property (weak, nonatomic) IBOutlet UITextField *tagText;

@property bool taging;
@end
