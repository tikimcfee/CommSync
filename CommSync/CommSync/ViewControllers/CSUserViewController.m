//
//  CSUserViewController.m
//  CommSync
//
//  Created by CommSync on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSUserViewController.h"
#import "AppDelegate.h"

@interface CSUserViewController ()
{
    NSArray *tableData;
}
@property (strong, nonatomic) CSSessionManager* sessionManager;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *userConnectionCount;

@end

@implementation CSUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    tableData = [NSArray arrayWithObjects:@"Egg Benedict", @"Mushroom Risotto", @"Full Breakfast", @"Hamburger", @"Ham and Egg Sandwich", @"Creme Brelee", @"White Chocolate Donut", @"Starbucks Coffee", @"Vegetable Curry", @"Instant Noodle with Egg", @"Noodle with BBQ Pork", @"Japanese Noodle with Pork", @"Green Tea", @"Thai Shrimp Cake", @"Angry Birds Cake", @"Ham and Cheese Panini", nil];
    
    NSLog(@"Loaded task view!");
    
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = d.globalSessionManager;
    NSInteger connectionCount = [_sessionManager.currentSession.connectedPeers count];
    self.userConnectionCount.title = [NSString stringWithFormat:@"%d", (int)connectionCount];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource Delegates
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = [tableData objectAtIndex:indexPath.row];
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [_sessionManager.currentSession.connectedPeers count];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
