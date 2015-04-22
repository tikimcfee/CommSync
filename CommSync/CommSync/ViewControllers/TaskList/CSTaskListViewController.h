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
@property (strong, nonatomic) NSString* user;
@property (strong, nonatomic) NSString* tag;
@property BOOL completed;

@property (strong, nonatomic) IBOutlet UISegmentedControl *completionToggleControl;


@end