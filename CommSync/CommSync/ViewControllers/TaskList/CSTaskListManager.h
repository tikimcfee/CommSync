//
//  CSTaskListManager.h
//  CommSync
//
//  Created by Ivan Lugo on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"

@interface CSTaskListManager : NSObject

@property (strong, nonatomic) NSMutableArray* currentTaskList;


- (void) insertTaskIntoList:(CSTaskRealmModel*)newTask;


@end
