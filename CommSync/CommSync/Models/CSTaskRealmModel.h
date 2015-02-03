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

typedef NS_ENUM(NSInteger, CSTaskPriority)
{
    CSTaskPriorityLow = 0,
    CSTaskPriorityMedium,
    CSTaskPriorityHigh
};

RLM_ARRAY_TYPE(CSCommentRealmModel);

@interface CSTaskRealmModel : RLMObject <NSCoding>

// Task persistence properties

@property NSString* UUID;
@property NSString* deviceID;
@property NSString* concatenatedID;

// Task information
@property NSString* taskTitle;
@property NSString* taskDescription;
@property CSTaskPriority taskPriority;



//@property RLMArray<CSCommentRealmModel> *comments;
//@property RLMArray<CSCommentRealmModel> *before;
//@property RLMArray<CSCommentRealmModel> *after;


// Task media
//@property NSData* taskImageRawData;

//@property id taskAudio;
//@property id taskVideo;
//@property id taskAttachmentData;

-(void) addTask: (CSCommentRealmModel *) newComment;

@end
