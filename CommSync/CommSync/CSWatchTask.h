//
//  WatchTask.h
//  CommSync
//
//  Created by Anna Stavropoulos on 3/14/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSWatchTask : NSObject

// Task persistence properties
@property NSString* UUID;
@property NSString* deviceID;
@property NSString* concatenatedID;

// Task information
@property NSString* taskTitle;
@property NSString* taskDescription;

@end
