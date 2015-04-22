//
//  CSTaskRevisionRealmModel.m
//  HubSync
//
//  Created by CommSync on 4/6/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskRevisionRealmModel.h"
#import "CSTaskRealmModel.h"

#define kRevisionID @"revisionID"
#define krevisionDate @"revisionDate"
#define kChangesDictionary @"changesDictionary"

@implementation CSTaskRevisionRealmModel : RLMObject

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.revisionID = [aDecoder decodeObjectForKey:kRevisionID];
        self.revisionDate = [aDecoder decodeObjectForKey:krevisionDate];
        self.changesDictionary = [aDecoder decodeObjectForKey:kChangesDictionary];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.revisionID forKey:kRevisionID];
    [aCoder encodeObject:self.revisionDate forKey:krevisionDate];
    [aCoder encodeObject:self.changesDictionary forKey:kChangesDictionary];
}

+(CSTaskRevisionRealmModel*)revisionModelWithModel:(CSTaskRevisionRealmModel*)model {
    CSTaskRevisionRealmModel* newModel = [CSTaskRevisionRealmModel new];
    newModel.revisionID = model.revisionID;
    newModel.revisionDate = model.revisionDate;
    
    newModel.changesDictionary = [NSData dataWithData:model.changesDictionary];
    
    return newModel;
}

+ (NSDictionary *)defaultPropertyValues {
    NSMutableDictionary* defaults = [NSMutableDictionary new];
    
//    @property NSString* revisionID;
//    @property NSDate* revisionDate;
//    @property NSData* changesDictionary;
    
    NSMutableDictionary* empty = [NSMutableDictionary new];
    NSData* emptyData = [NSKeyedArchiver archivedDataWithRootObject:empty];
    
    [defaults setObject:[[NSUUID UUID] UUIDString] forKey:@"revisionID"];
    [defaults setObject:[NSDate dateWithTimeIntervalSince1970:1] forKey:@"revisionDate"];
    
    
    // Dictionary should be formatted:
    /* 
        {
            "property_changed":
            {
                    "from":OLD,
                    "to"  :NEW
            },
             "property_changed":
             {
                    "from":OLD,
                    "to"  :NEW
             },
        }
    */
    [defaults setObject:emptyData forKey:@"changesDictionary"];
    
    return defaults;
}

- (void)forTask:(CSTaskRealmModel*)task reviseProperty:(CSTaskProperty)property to:(id)newData {
    
    // unarchive the data *that already exists on the current revision*
    // *this is done to add more than a single change to the revision model*
    NSMutableDictionary* originalRevisions = [NSKeyedUnarchiver unarchiveObjectWithData:_changesDictionary];
    
    // new revision data
    NSMutableDictionary* newRevisionData = [NSMutableDictionary new];
    
    // get the property lookup string
    NSString* propertyString = [CSTaskRealmModel stringForProperty:property];
    
    // if there are no revisions yet, we need to construct a base
    id oldValue;
    if(task.revisions.count == 0) {
        // get the property value we're interested in ; it is 'from'
        oldValue = [task valueForProperty:property];
        
    } else { // if there are already revisions, get the latest one ; it is 'from'
        CSTaskRevisionRealmModel* lastRevision = [task.revisions lastObject];
        NSData* oldData = lastRevision.changesDictionary;
        NSMutableDictionary* lastRevisionDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:oldData];
        NSMutableDictionary* oldProperties = [lastRevisionDictionary valueForKey:propertyString];
        oldValue = [oldProperties valueForKey:@"to"];
    }
    // the last revision may not have had a change for the property; if so, get the current value
    if(!oldValue) {
        oldValue = [task valueForProperty:property];
    }
    [newRevisionData setValue:oldValue forKey:@"from"];
    
    // make a new mut.dict. for the property with 'to' == newData
    [newRevisionData setValue:newData forKey:@"to"];
    
    // revision has been created ; add it to the original revisions, and set that to the task
    [originalRevisions setValue:newRevisionData forKey:propertyString];
    NSData* newRevisions = [NSKeyedArchiver archivedDataWithRootObject:originalRevisions];
    _changesDictionary = newRevisions;
}

- (void)save:(CSTaskRealmModel*)sourceTask {
    _revisionDate = [NSDate new];
}

+ (NSString*)primaryKey {
    return @"revisionID";
}

@end
