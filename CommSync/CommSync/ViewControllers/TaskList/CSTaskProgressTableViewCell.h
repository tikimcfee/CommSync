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
#import "TLIndexPathTools.h"

@class CSNewTaskResourceInformationContainer;

@interface CSTaskProgressTableViewCell : UITableViewCell

// View hierarcy and UI
@property (strong, nonatomic) IBOutlet M13ProgressViewRing *progressRingView;
@property (strong, nonatomic) IBOutlet UILabel *taskStatusLabel;

// Task information and state
@property (strong, nonatomic) NSString* resourceName;
@property (strong, nonatomic) void (^progressCompletionBlock)(CSTaskProgressTableViewCell*, TLIndexPathUpdates* updates);


// Configuration method
- (void)configureWithIdentifier:(NSString*)container;

@end
