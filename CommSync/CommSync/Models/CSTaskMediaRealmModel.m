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
    
    return @{@"mediaData":emptyData, @"mediaType":type};
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.mediaData = [aDecoder decodeObjectForKey:kMediaData];
        self.mediaType = [((NSNumber*)[aDecoder decodeObjectForKey:kMediaType]) integerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_mediaData forKey:kMediaData];
    [aCoder encodeObject:[NSNumber numberWithInteger:_mediaType] forKey:kMediaType];
}

+(CSTaskMediaRealmModel*)mediaModelWithModel:(CSTaskMediaRealmModel*)model {
    CSTaskMediaRealmModel* newModel = [CSTaskMediaRealmModel new];
    newModel.mediaType = model.mediaType;
    newModel.mediaData = [NSData dataWithData:model.mediaData];
    
    return newModel;
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

@end
