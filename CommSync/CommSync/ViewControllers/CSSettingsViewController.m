//
//  CSSettingsViewController.m
//  CommSync
//
//  Created by CommSync on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSSettingsViewController.h"

@interface CSSettingsViewController ()

@end

@implementation CSSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.settingsList = @[@"Send Pulse", @"Tear Down", @"Rebuild", @"Change Username", @"Populate Tasks", @"NUKE SESSION", @"NUKE DATABASE"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)nukeSession
{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CSSessionManager *sessionManager = app.globalSessionManager;
    
    [sessionManager nukeSession];
}

- (void)nukeRealm
{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CSSessionManager *sessionManager = app.globalSessionManager;
    
    [sessionManager nukeRealm];
}



- (IBAction)sendGlobalPulse {
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CSSessionManager* sessionManager = d.globalSessionManager;
    
    [sessionManager sendPulseToPeers];
}

- (IBAction)tearDown {
    //    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    //    CSSessionManager* sessionManager = d.globalSessionManager;
    
}

- (IBAction)rebuild {
    
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CSSessionManager* sessionManager = d.globalSessionManager;
    
    MCSession* s =[[MCSession alloc] initWithPeer:sessionManager.myPeerID];
    s.delegate = sessionManager;
    sessionManager.currentSession = s;
    
}

-(void) populate
{
    
    NSLog(@"test");
    //get the database object
     _realm = [RLMRealm defaultRealm];

    for(int i = 0; i < 5; i++){
        
        
        //allocate space for the task object and initialize the object
        self.tempTask = [[CSTaskRealmModel alloc] init];
        
        //populate variables
        
        _tempTask.UUID = [NSString stringWithFormat:@"%s %d", "UUID", i];
        _tempTask.deviceID = [NSString stringWithFormat:@"%s %d", "DID", i];
        _tempTask.concatenatedID = [NSString stringWithFormat:@"%s %d", "CID", i];
        
        _tempTask.taskPriority = CSTaskPriorityLow;
        
        _tempTask.taskTitle = [NSString stringWithFormat:@"%s %d", "Title", i];
        _tempTask.taskDescription = [NSString stringWithFormat:@"%s %d", "Description", i];
        
        //start write
        [_realm beginWriteTransaction];
        //add the object to the list of tasks
        [_realm addObject:_tempTask];
        
        //write to the database
        [_realm commitWriteTransaction];
        
    }
    
    
   
}



- (IBAction)resync {
    
     //need to redo after fixing realm tasks
    /*
    //If something bad happens this will catch the error and give a printout reading of the issue
    NSError* error;
    
    //get the session manager
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CSSessionManager* sessionManager = d.globalSessionManager;
    
    //grab the task list and pack it into a data packet that can be sent
    NSMutableArray* taskList = [d.globalSessionManager currentTaskList];
    NSData* packedTaskList = [NSKeyedArchiver archivedDataWithRootObject: taskList];
    
    
    //take the packed task list and send it to every connected peer. This should cause the delegate to automatically call the didReceiveInvitationFromPeer method where all other users will upack it and add it to their task list
    [sessionManager.currentSession sendData:packedTaskList
                                    toPeers:sessionManager.currentSession.connectedPeers
                                   withMode:MCSessionSendDataReliable
                                      error:&error];
    
    NSLog(@"test"); */
    
}


#pragma Mark - Table Population

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.settingsList count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *SimpleIdentifier = @"SimpleIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleIdentifier];
    
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SimpleIdentifier];
    }
    
    cell.textLabel.text = self.settingsList[indexPath.row];
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    switch (indexPath.row) {
        case 0:
            [self sendGlobalPulse];
            break;
            
        case 1:
            [self tearDown];
            break;
            
        case 2:
            [self rebuild];
            break;
            
        case 3:
            [self resync];
            break;
            
        case 4:
            [self populate];
            break;

        case 5:
            [self nukeSession];
            break;
            
        case 6:
            [self nukeRealm];
            break;
    }
    
}




@end
