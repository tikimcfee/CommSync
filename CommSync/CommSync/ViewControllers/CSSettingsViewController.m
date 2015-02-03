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
    
    //list of settings
    self.settingsList = @[@"Send Pulse", @"Tear Down" , @"Rebuild", @"Change Username"];
    
    //list of generic names
    self.namesList = @[@"Mike", @"Ivan", @"Darin", @"Mark", @"Isasi", @"Anna", @"Generic Name", @"Red", @"Blue", @"Ash", @"Gary"];
    
    //Tells the page to display the list of settings
    _namePage = false;
    self.activeList = self.settingsList;
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

-(void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){
     
    }
}

-(void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [_myView setEditing:editing animated:animated];
}

- (IBAction)sendGlobalPulse:(UIButton *)sender {
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CSSessionManager* sessionManager = d.globalSessionManager;
    
    [sessionManager sendPulseToPeers];
}

- (IBAction)tearDown:(id)sender {
//    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
//    CSSessionManager* sessionManager = d.globalSessionManager;

}

- (IBAction)rebuild:(id)sender {
    
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CSSessionManager* sessionManager = d.globalSessionManager;
    
    MCSession* s =[[MCSession alloc] initWithPeer:sessionManager.myPeerID];
    s.delegate = sessionManager;
    sessionManager.currentSession = s;
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.activeList count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *SimpleIdentifier = @"SimpleIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleIdentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SimpleIdentifier];
    }
    
    cell.textLabel.text = self.activeList[indexPath.row];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //if the change user name is selected then display user names
    if( indexPath.row == 3 )
    {
        _activeList= _namesList;
        _namePage = true;
        
    }
}



@end
