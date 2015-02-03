//
//  CSSettingsViewController.h
//  CommSync
//
//  Created by CommSync on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CSSessionManager.h"

@interface CSSettingsViewController : UITableViewController

@property (strong, nonatomic) IBOutlet UIButton *sendPulse;
@property (strong, nonatomic) IBOutlet UIButton *tearDown;
@property (strong, nonatomic) IBOutlet UIButton *rebuild;

@end
