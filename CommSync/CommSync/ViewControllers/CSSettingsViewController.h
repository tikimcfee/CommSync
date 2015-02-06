//
//  CSSettingsViewController.h
//  CommSync
//
//  Created by CommSync on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>
#import "CSTaskRealmModel.h"
#import "AppDelegate.h"
#import "CSSessionManager.h"

@interface CSSettingsViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>

@property (copy, nonatomic) NSArray *settingsList;
@property (copy, nonatomic) NSArray *test;
@property (weak, nonatomic) IBOutlet UITableView *myView;

@property (strong, nonatomic) CSTaskRealmModel *tempTask;
@property (strong, nonatomic) CSCommentRealmModel *tempComment;
@property (weak, nonatomic) RLMRealm* realm;

- (IBAction)resync;
-(void) populate;

@end
