//
//  CSTaskRevisionRealmModel.h
//  HubSync
//
//  Created by CommSync on 4/6/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Realm/Realm.h>
//#import "CSTaskRealmModel.h"
@class CSTaskRealmModel;

typedef NS_ENUM(NSInteger, CSTaskProperty)
{
    CSTaskProperty_UUID = 0,
    CSTaskProperty_deviceID,
    CSTaskProperty_concatenatedID,
    CSTaskProperty_assignedID,
    CSTaskProperty_tag,
    CSTaskProperty_completed,
    CSTaskProperty_taskTitle,
    CSTaskProperty_taskDescription,
    CSTaskProperty_taskPriority,
    CSTaskProperty_taskImages_NSDataArray_JPEG,
    CSTaskProperty_taskAudio
};

@interface CSTaskRevisionRealmModel : RLMObject <NSCoding>

@property NSString* revisionID;
@property NSDate* revisionDate;

@property NSData* changesDictionary;

- (void)forTask:(CSTaskRealmModel*)task reviseProperty:(CSTaskProperty)property to:(id)newData;
- (void)save:(CSTaskRealmModel*)sourceTask;

@end

RLM_ARRAY_TYPE(CSTaskRevisionRealmModel)