//
//  CSPictureViewController.m
//  CommSync
//
//  Created by Anna Stavropoulos on 2/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSPictureViewController.h"
#import "CSPictureController.h"
#import "ImageCell.h"

@interface CSPictureViewController ()
//@property int activePic;

@end

@implementation CSPictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//as many cells as the number of comments
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
     return [_taskImages count];
}

//inserts the comments into the cells one comment per cell
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ImageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pictureCell"];
    cell.pictureView.image = [_taskImages objectAtIndex:indexPath.row];
    return cell;

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (_header.frame.size.height / 2) - 20;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"pictureView" sender:[_taskImages objectAtIndex:indexPath.row]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"pictureView"]) {
        
        CSPictureController *temp = segue.destinationViewController;
        [temp.pictureImage setImage:sender];
    }
    

}


@end
