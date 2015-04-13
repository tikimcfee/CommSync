//
//  CSRealmWriteOperation.h
//  CommSync
//
//  Created by Ivan Lugo on 2/20/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSTaskRealmModel.h"

@interface CSRealmWriteOperation : NSOperation

@property CSTaskRealmModel* pendingTask;
@property CSTaskRealmModel* untouchedPendingTask;

@end
