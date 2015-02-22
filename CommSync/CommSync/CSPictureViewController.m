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
@property int activePic;
@end

@implementation CSPictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _activePic = -1;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
        ImageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pictureCell"];
        cell.pictureView.image = [_taskImages objectAtIndex:indexPath.row];
        return cell;

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

        if(_activePic == indexPath.row){
            [_top setActive:NO];
            UIImage *temp = [_taskImages objectAtIndex:indexPath.row] ;
            _containerHeight.constant = temp.size.height;
            _containerWidth.constant = temp.size.width;
            _distanceEdge.constant = temp.size.width + 20;
            
            
            return temp.size.height;
        }
    return 200;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
        if(_activePic ==  indexPath.row)
        {
            _activePic = -1;
            _containerHeight.constant = 200;
            _containerWidth.constant = 200;
            _distanceEdge.constant = 8;
            [_top setActive:YES];
          
        }
        else _activePic = indexPath.row;
        
        [[self tableView] beginUpdates];
        
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil]withRowAnimation: UITableViewRowAnimationAutomatic];
        [[self tableView] endUpdates];
    
}

@end
