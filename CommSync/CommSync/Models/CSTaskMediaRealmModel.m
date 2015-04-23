//
//  CSTaskMediaRealmModel.m
//  HubSync
//
//  Created by CommSync on 4/9/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskMediaRealmModel.h"

@implementation CSTaskMediaRealmModel

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues
{
    NSNumber* type = [NSNumber numberWithInt:-1];
    NSData* emptyData = [NSData data];
    NSString* UUID = [[NSUUID UUID] UUIDString];
    NSNumber* isOld = [NSNumber numberWithBool:NO];
    
    return @{@"mediaData":emptyData, @"mediaType":type, @"uniqueMediaID":UUID, @"isOld":isOld};
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.mediaData = [aDecoder decodeObjectForKey:kMediaData];
        self.mediaType = [((NSNumber*)[aDecoder decodeObjectForKey:kMediaType]) integerValue];
        self.uniqueMediaID = [aDecoder decodeObjectForKey:kUniqueMedia];
        self.isOld = [aDecoder decodeObjectForKey:kIsOld];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_mediaData forKey:kMediaData];
    [aCoder encodeObject:[NSNumber numberWithInteger:_mediaType] forKey:kMediaType];
    [aCoder encodeObject:self.uniqueMediaID forKey:kUniqueMedia];
    [aCoder encodeBool:self.isOld forKey:kIsOld];
}

+(CSTaskMediaRealmModel*)mediaModelWithModel:(CSTaskMediaRealmModel*)model {
    CSTaskMediaRealmModel* newModel = [CSTaskMediaRealmModel new];
    newModel.mediaType = model.mediaType;
    newModel.mediaData = [NSData dataWithData:model.mediaData];
    newModel.uniqueMediaID = model.uniqueMediaID;
    
    return newModel;
}

+(NSString *)primaryKey {
    return @"uniqueMediaID";
}
// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

@end
