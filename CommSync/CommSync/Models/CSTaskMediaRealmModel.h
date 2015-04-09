//
//  CSTaskMediaRealmModel.h
//  HubSync
//
//  Created by CommSync on 4/9/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Realm/Realm.h>

typedef NS_ENUM(NSInteger, CSTaskMediaType)
{
    CSTaskMediaType_Audio = 0,
    CSTaskMediaType_Photo
};

@interface CSTaskMediaRealmModel : RLMObject

@property NSData* mediaData;
@property CSTaskMediaType mediaType;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<CSTaskMediaRealmModel>
RLM_ARRAY_TYPE(CSTaskMediaRealmModel)
