//
//  CSTaskViewController.h
//  CommSync
//
//  Created by CommSync on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

#import "TLIndexPathTools.h"

@interface CSTaskListViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>
@property (assign, nonatomic) NSString* user;
@property (assign, nonatomic) NSString* tag;
@property BOOL completed;

@property (strong, nonatomic) IBOutlet UISegmentedControl *completionToggleControl;


@end