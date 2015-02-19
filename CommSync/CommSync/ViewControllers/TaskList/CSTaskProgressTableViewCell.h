//
//  CSTaskProgressTableViewCell.h
//  CommSync
//
//  Created by CommSync on 2/16/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>
#import "CSTaskRealmModel.h"
#import "M13ProgressViewRing.h"

@interface CSTaskProgressTableViewCell : UITableViewCell

// View hierarcy and UI
@property (weak, nonatomic) IBOutlet M13ProgressViewRing *progressRingView;
@property (weak, nonatomic) IBOutlet UILabel *taskStatusLabel;
@property (strong, nonatomic) NSProgress* loadProgress;

// Task information and state
@property (strong, nonatomic) NSDictionary *sourceTask;
@property (strong, nonatomic) NSString* resourceName;
@property (strong, nonatomic) void (^progressCompletionBlock)(NSDictionary*);


// Configuration method
- (void)configureWithSourceInformation:(NSDictionary *)task;

@end
