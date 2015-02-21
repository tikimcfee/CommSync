//
//  CSPictureViewController.m
//  CommSync
//
//  Created by Anna Stavropoulos on 2/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSPictureViewController.h"
#import "ImageCell.h"

@interface CSPictureViewController ()

@end

@implementation CSPictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//as many cells as the number of comments
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_taskImages count];
}

//inserts the comments into the cells one comment per cell
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
        ImageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell"];
        cell.pictureView.image = [_taskImages objectAtIndex:indexPath.row];
        return cell;
 
}

@end
