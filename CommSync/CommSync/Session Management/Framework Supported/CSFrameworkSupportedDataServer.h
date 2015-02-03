//
//  CSFrameworkSupportedDataServer.h
//  CommSync
//
//  Created by CommSync on 2/2/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSConnectivityConstants.h"
#import "CSFrameworkSupportedConnectivityManager.h"

@interface CSFrameworkSupportedDataServer : NSObject

+ (CSFrameworkSupportedDataServer*) sharedServer;

@end
