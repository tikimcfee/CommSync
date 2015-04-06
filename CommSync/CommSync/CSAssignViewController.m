//
//  CSAssignViewController.m
//  CommSync
//
//  Created by Anna Stavropoulos on 4/4/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSAssignViewController.h"

@interface CSAssignViewController (){
    
NSMutableArray* pickerData;
    CSSessionManager *sessionManager;
}
@end

@implementation CSAssignViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    sessionManager = app.globalSessionManager;
    
    // Do any additional setup after loading the view.
    
    pickerData = [[NSMutableArray alloc] init];
    
    if(!_taging){
        [_tagLabel setHidden:true];
        [_tagText setHidden:true];
        
        [pickerData addObject:@"Unassigned"];
        [pickerData addObject:@"Assign to self"];

        [_assignmentLabel setText:_sourceTask.assignedID];
        [pickerData addObjectsFromArray: sessionManager.peerHistory.allKeys];
    }
    else{
        [pickerData addObject:@"None"];
        if([_sourceTask.tag isEqualToString:@""] ) [_assignmentLabel setText:@"No Tags"];
        else [_assignmentLabel setText:_sourceTask.tag];
        [pickerData addObjectsFromArray:sessionManager.allTags.allKeys];
    }
    
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


// The number of columns of data
- (int)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (int)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return pickerData.count;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return pickerData[row];
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(row == 1) _tempAssignment = sessionManager.myPeerID.displayName;
    else   _tempAssignment = pickerData[row];
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)assign:(id)sender {
    
    //assign to the user and save, if assigning to self user own display name
    [[RLMRealm defaultRealm] beginWriteTransaction];
    if(!_taging) _sourceTask.assignedID = _tempAssignment;
    
    
    else if(![_tempAssignment isEqualToString:@"None"] && ([[_tagText text] isEqualToString:@""] || [[_tagText text] isEqualToString:@"Create New Tag"])) _sourceTask.tag = _tempAssignment;
    
    else{
        [sessionManager addTag:_tagText.text];
        _sourceTask.tag = _tagText.text;
    }
    
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
