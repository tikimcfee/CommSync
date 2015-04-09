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

+ (NSDictionary *)defaultPropertyValues {
    NSMutableDictionary* defaults = [NSMutableDictionary new];
    
//    @property NSString* revisionID;
//    @property NSDate* revisionDate;
//    @property NSData* changesDictionary;
    
    NSMutableDictionary* empty = [NSMutableDictionary new];
    NSData* emptyData = [NSKeyedArchiver archivedDataWithRootObject:empty];
    
    [defaults setObject:@"BAD_ID" forKey:@"revisionID"];
    [defaults setObject:[NSDate distantPast] forKey:@"revisionDate"];
    
    
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
    
    /* The code below is not very useful; a single revision should hold a SINGLE
     set of property changes, and should not be repeatedly updated. Keeping this here
     as a reminder of that fact.
     */
//    // check if there is currently a revision for the property
//    NSMutableDictionary* oldDictionary = nil;
//    if([originalRevisions valueForKey:propertyString]) {
//        oldDictionary = [originalRevisions valueForKey:propertyString];
//    }
//    // if there isn't an old dictionary, construct a to/from with the task
//    else {
//        id oldValue = [task valueForProperty:property];
//        oldDictionary = [NSMutableDictionary dictionaryWithDictionary:@{@"from":oldValue}];
//    }
//    
//    // if there is an old revision, take its 'to', set it as a new 'from'
//    if(oldDictionary && [oldDictionary valueForKey:@"to"]) {
//        [oldDictionary setValue:[oldDictionary valueForKey:@"to"]
//                         forKey:@"from"];
//    }
    
    
    // make a new mut.dict. for the property with 'to' == newData
    [newRevisionData setValue:newData forKey:@"to"];
    
    // revision has been created ; add it to the original revisions, and set that to the task
    [originalRevisions setValue:newRevisionData forKey:propertyString];
    NSData* newRevisions = [NSKeyedArchiver archivedDataWithRootObject:originalRevisions];
    _changesDictionary = newRevisions;
}

- (void)save:(CSTaskRealmModel*)sourceTask {
    NSString* U = [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c",
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65];
    
    _revisionID = [NSString stringWithFormat:@"%@_%ld", U, sourceTask.revisions.count];
    _revisionDate = [NSDate new];
}

+ (NSString*)primaryKey {
    return @"revisionID";
}

@end
