//
//  AppDelegate.h
//  CommSync
//
//  Created by Ivan Lugo on 9/30/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "CSSessionManager.h"



@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

# pragma Application-wide sessions manager
@property (strong, nonatomic) CSSessionManager* globalSessionManager;
@property (strong, nonatomic) NSString* userDisplayName;


- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end

