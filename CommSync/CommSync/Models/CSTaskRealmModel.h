//
//  CSTaskRealmModel.h
//  CommSync
//
//  Created by Ivan Lugo on 1/27/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <Realm/Realm.h>
#import "CSCommentRealmModel.h"
#import "CSTaskRevisionRealmModel.h"

@class CSTaskTransientObjectStore;

typedef NS_ENUM(NSInteger, CSTaskPriority)
{
    CSTaskPriorityLow = 0,
    CSTaskPriorityMedium,
    CSTaskPriorityHigh
};

@interface CSTaskRealmModel : RLMObject

@property RLMArray<CSCommentRealmModel> *comments;
@property RLMArray<CSTaskRevisionRealmModel> *revisions;

// Task persistence properties
@property NSString* UUID;
@property NSString* deviceID;
@property NSString* concatenatedID;
@property NSString* assignedID;

@property NSString* tag;
@property BOOL completed;


// Task information
@property NSString* taskTitle;
@property NSString* taskDescription;
@property CSTaskPriority taskPriority;

// Task media
@property NSData* taskImages_NSDataArray_JPEG;
@property NSData* taskAudio;

// Transient backing model
@property (strong, nonatomic) CSTaskTransientObjectStore* transientModel;
- (CSTaskTransientObjectStore*)transientModel;

- (void) addComment: (CSCommentRealmModel *) newComment;
- (void) addRevision:(CSTaskRevisionRealmModel*)revision;

+ (NSMutableArray*)getTransientTaskList: (NSString*)user withTag: (NSString*)tag completionStatus: (BOOL) completed;

+ (NSString*)stringForProperty:(CSTaskProperty)property;
- (id)valueForProperty:(CSTaskProperty)property;

@end
