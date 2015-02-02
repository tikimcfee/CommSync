//
//  JKPeer.h
//  GeoStormEmbedded
//
//  Created by Judit Klein on 4/21/14.
//  Copyright (c) 2014 Judit Klein. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JKPeer : NSObject {
    
    NSNetService *peerNetService;
    NSString *peerName;
    NSString *peerMajor;
    NSString *peerOSType;
    
}
- (instancetype)initWithNetService:(NSNetService*)netService Name:(NSString*)Name Major:(NSString*)Major osType:(NSString*)osType;

@property (nonatomic,retain) NSNetService *peerNetService;
@property (nonatomic,retain) NSString *peerName;
@property (nonatomic,retain) NSString *peerMajor;
@property (nonatomic,retain) NSString *peerOSType;


@end
