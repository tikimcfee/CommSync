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
    
    self.settingsList = @[@"Send Pulse", @"Tear Down", @"Rebuild", @"Change Username"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
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



- (IBAction)resync {
    
    //If something bad happens this will catch the error and give a printout reading of the issue
    NSError* error;
    
    //get the session manager
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CSSessionManager* sessionManager = d.globalSessionManager;
    
    //grab the task list and pack it into a data packet that can be sent
    NSMutableArray* taskList = [d.globalTaskManager currentTaskList];
    NSData* packedTaskList = [NSKeyedArchiver archivedDataWithRootObject: taskList];
    
    
    //take the packed task list and send it to every connected peer. This should cause the delegate to automatically call the didReceiveInvitationFromPeer method where all other users will upack it and add it to their task list
    [sessionManager.currentSession sendData:packedTaskList
                                    toPeers:sessionManager.currentSession.connectedPeers
                                   withMode:MCSessionSendDataReliable
                                      error:&error];
    

    
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

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    switch (indexPath.row) {
        case 1:
            [self sendGlobalPulse];
            break;
            
        case 2:
            [self tearDown];
            break;
            
        case 3:
            [self rebuild];
            break;
            
        case 4:
            [self resync];
    }
    
}

@end