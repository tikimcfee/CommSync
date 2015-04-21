//
//  CSSettingsViewController.m
//  CommSync
//
//  Created by CommSync on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSSettingsViewController.h"
#import "CSUserRealmModel.h"
#import "UINavigationBar+CommSyncStyle.h"

@interface CSSettingsViewController ()
@property (copy, nonatomic) void (^nukeSessionHandler)(UIAlertAction *);
@property (copy, nonatomic) void (^nukeDatabaseHandler)(UIAlertAction *);
@property (copy, nonatomic) void (^nukePeerHistoryHandler)(UIAlertAction *);
@property (copy, nonatomic) void (^nukeChatHistoryHandler)(UIAlertAction *);
@end

@implementation CSSettingsViewController
{
    CSSessionManager *_sessionManager;
    AppDelegate *_app;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_avatarPic setImage: [UIImage imageNamed:_sessionManager.myUserModel.getPicture]];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _sessionManager = _app.globalSessionManager;

    
    __weak CSSettingsViewController *weakSelf = self;
    
    self.nukeSessionHandler = ^(UIAlertAction *action){
        [weakSelf nukeSession];
    };
    
    self.nukeDatabaseHandler = ^(UIAlertAction *action){
        [weakSelf nukeDatabase];
    };
    
    self.nukePeerHistoryHandler = ^(UIAlertAction *action){
        [weakSelf nukePeerHistory];
    };
    
    self.nukeChatHistoryHandler = ^(UIAlertAction *action){
        [weakSelf nukeChatHistory];
    };
    
    [self.navigationController.navigationBar setupCommSyncStyle];
}

- (void)showAlertWithHandler:(void (^)(UIAlertAction *))actionHandler {
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Are you sure?"
                                                                   message:@"This is a destructive action."
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSString *title = @"Yes";
    NSIndexPath* path;
    if (actionHandler == self.nukeDatabaseHandler) {
        path = [NSIndexPath indexPathForRow:1 inSection:1];
        title = @"Delete All Tasks";
    }
    else if (actionHandler == self.nukeSessionHandler) {
        path = [NSIndexPath indexPathForRow:0 inSection:1];
        title = @"Restart Session";
    }
    else if (actionHandler == self.nukePeerHistoryHandler) {
        path = [NSIndexPath indexPathForRow:2 inSection:1];
        title = @"Clear Peer History";
    }
    else if (actionHandler == self.nukeChatHistoryHandler) {
        path = [NSIndexPath indexPathForRow:3 inSection:1];
        title = @"Delete Chat Messages";
    }
    
    CGRect rectOfCellInTableView = [self.tableView rectForRowAtIndexPath:path];
    CGRect rectOfCellInSuperview = [self.tableView convertRect:rectOfCellInTableView toView:[self.tableView superview]];
    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect = rectOfCellInSuperview;
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:title
                                                            style:UIAlertActionStyleDestructive
                                                          handler:actionHandler];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)nukeSession {
    [_sessionManager nukeSession];
}

- (void)nukeDatabase {
    [_sessionManager nukeRealm];
}

- (void)nukePeerHistory {
    //removes all former peers from the data base and replaces the peer history list with current list
    [_sessionManager nukeHistory];
}

- (void)nukeChatHistory {
    [_sessionManager nukeChatHistory];
}

- (void)changeUsernameTo:(NSString*)name {
    
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"userDisplayName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)promptForNewUsername {
    
    __weak CSSettingsViewController *weakSelf = self;
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Enter Username"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
   
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
//        textField.placeholder = NSLocalizedString(@"Username", @"UsernamePlaceholder");
        textField.placeholder = _app.userDisplayName;
    }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              UITextField *username = alert.textFields.firstObject;
                                                              [weakSelf changeUsernameTo:username.text];
                                                          }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil];
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Tableview Delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        
        switch (indexPath.row) {
            case 0:
                [self promptForNewUsername];
                break;
        }
        
    }
    
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                [self showAlertWithHandler:_nukeSessionHandler];
                break;
                
            case 1:
                [self showAlertWithHandler:_nukeDatabaseHandler];
                break;
                
            case 2:
                [self showAlertWithHandler:_nukePeerHistoryHandler];
                break;
                
            case 3:
                [self showAlertWithHandler:_nukeChatHistoryHandler];
                break;
            case 4: break;
            default:
                NSLog(@"Settings ERROR: This selection has no action");
                break;
        }
    }
    
}


@end
