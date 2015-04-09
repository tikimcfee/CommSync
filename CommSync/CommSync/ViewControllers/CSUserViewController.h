//
//  CSUserViewController.h
//  CommSync
//
//  Created by CommSync on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSuserRealmModel.h"
@interface CSUserViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UINavigationItem *navBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filterButton;
@property BOOL filter;

-(void) checkMessages;
@end
