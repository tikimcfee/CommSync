//
//  CSUserDetailView.m
//  CommSync
//
//  Created by Anna Stavropoulos on 3/7/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSUserDetailView.h"
#import "SlackTestViewController.h"

@interface CSUserDetailView ()

@end

@implementation CSUserDetailView

- (void)viewDidLoad {
    
    [super viewDidLoad];
        // Do any additional setup after loading the view.
    _nameLabel.text = _peerID.displayName;
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
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"personalChatSegue"])
    {
        SlackTestViewController *vc = [segue destinationViewController];
        
        [vc setPeerID:_peerID];
    
    }
}
@end
