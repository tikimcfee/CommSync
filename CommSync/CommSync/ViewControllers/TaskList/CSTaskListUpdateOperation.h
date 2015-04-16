//
//  CSTaskListUpdateOperation.h
//  CommSync
//
//  Created by Ivan Lugo on 2/20/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TLIndexPathController.h"
#import "CSTaskProgressTableViewCell.h"

@class TLIndexPathUpdates;
@interface CSTaskListUpdateOperation : NSOperation <TLIndexPathControllerDelegate>

@property (weak, nonatomic) UITableView* tableviewToUpdate;

@property (strong, nonatomic) void (^reloadBlock)();
@property (strong, nonatomic) TLIndexPathController* indexPathController;
@property (assign, nonatomic) BOOL tableviewIsVisible;

@end
