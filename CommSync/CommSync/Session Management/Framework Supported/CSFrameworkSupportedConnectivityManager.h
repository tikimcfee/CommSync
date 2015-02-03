//
//  CSFrameworkSupportedConnectivityManager.h
//  CommSync
//
//  Created by CommSync on 2/2/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JKPeerConnectivity.h"
#import "CSConnectivityConstants.h"
#import "CSFrameworkSupportedDataServer.h"

@interface CSFrameworkSupportedConnectivityManager : NSObject <JKPeerConnectivityDelegate>

+ (CSFrameworkSupportedConnectivityManager*) sharedConnectivityManager;

@end
