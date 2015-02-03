//
//  CSTaskListManager.h
//  CommSync
//
//  Created by Ivan Lugo on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTask.h"

@interface CSTaskListManager : NSObject

@property (strong, nonatomic) CSTask* rootTask;
@property (strong, nonatomic) CSTask* currentTask;
@property (strong, nonatomic) NSMutableArray* currentTaskList;


- (void) insertTaskIntoList:(CSTask*)newTask;


@end
