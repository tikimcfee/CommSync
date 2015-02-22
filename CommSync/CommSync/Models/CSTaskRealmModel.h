//
//  CSTaskRealmModel.h
//  CommSync
//
//  Created by Ivan Lugo on 1/27/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>
#import "CSCommentRealmModel.h"

@class CSTaskTransientObjectStore;

typedef NS_ENUM(NSInteger, CSTaskPriority)
{
    CSTaskPriorityLow = 0,
    CSTaskPriorityMedium,
    CSTaskPriorityHigh
};

@interface CSTaskRealmModel : RLMObject

@property RLMArray<CSCommentRealmModel> *comments;

// Task persistence properties
@property NSString* UUID;
@property NSString* deviceID;
@property NSString* concatenatedID;

// Task information
@property NSString* taskTitle;
@property NSString* taskDescription;
@property CSTaskPriority taskPriority;

// Task media
@property NSData* taskImages_NSDataArray_JPEG;
@property NSData* taskAudio;

- (void) addComment: (CSCommentRealmModel *) newComment;

- (CSTaskTransientObjectStore*) getTransientObjectForModel;
+ (NSMutableArray*) getTransientTaskList;

@end
