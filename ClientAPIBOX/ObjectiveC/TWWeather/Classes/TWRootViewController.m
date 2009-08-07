//
//  TWRootViewController.m
//  TWWeather
//
//  Created by zonble on 2009/07/31.
//

#import "TWRootViewController.h"
#import "TWLoadingCell.h"
#import "TWAPIBox.h"
#import "TWErrorViewController.h"
#import "TWOverviewViewController.h"
#import "TWForecastTableViewController.h"
#import "TWForecastResultTableViewController.h"
#import "TWWeekTableViewController.h"
#import "TWWeekTravelTableViewController.h"
#import "TWThreeDaySeaTableViewController.h"
#import "TWNearSeaTableViewController.h"
#import "TWTideTableViewController.h"
#import "TWImageTableViewController.h"
#import "TWAboutViewController.h"
#import "TWLocationSettingTableViewController.h"
#import "TWWeatherAppDelegate.h"
#import "TWForecastResultCell.h"

@implementation TWRootViewController

- (void)dealloc
{
	[warningArray release];
	[super dealloc];
}
- (void)viewDidUnload
{
	// Release anything that can be recreated in viewDidLoad or on demand.
	// e.g. self.myOutlet = nil;
	[super viewDidLoad];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
	self.title = @"台灣天氣";
	if (!warningArray) {
		warningArray = [[NSMutableArray alloc] init];
	}
	[[TWAPIBox sharedBox] fetchWarningsWithDelegate:self userInfo:nil];
}

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark -

- (IBAction)changeCurrentLocationAction:(id)sender
{
	if (isLoadingOverview) {
		return;
	}
	
	TWLocationSettingTableViewController *controller = [[TWLocationSettingTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
	[controller release];
	[self presentModalViewController:navController animated:YES];
	[navController release];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 3;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (section == 0) {
		return [warningArray count];
	}
	else if (section == 1) {
		return 8;
	}
	else if (section == 2) {
		return 1;
	}	
    return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *CellIdentifier = @"Cell";
	static NSString *NormalIdentifier = @"NormalCell";
    
    if (indexPath.section == 0) {
		TWLoadingCell *cell = (TWLoadingCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[TWLoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		}
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		NSDictionary *dictionary = [warningArray objectAtIndex:indexPath.row];
		cell.textLabel.text = [dictionary objectForKey:@"name"];
		return cell;
	}
	else if (indexPath.section == 1) {
		TWLoadingCell *cell = (TWLoadingCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[TWLoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		}
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		if (indexPath.row != 0) {
			[cell stopAnimating];
		}		
		switch (indexPath.row) {
			case 0:
				cell.textLabel.text = @"關心天氣";
				if (isLoadingOverview) {
					[cell startAnimating];
				}
				else {
					[cell stopAnimating];
				}
				break;				
			case 1:
				cell.textLabel.text = @"今明預報";
				break;
			case 2:
				cell.textLabel.text = @"一週天氣";
				break;				
			case 3:
				cell.textLabel.text = @"一週旅遊";
				break;				
			case 4:
				cell.textLabel.text = @"三天漁業";
				break;				
			case 5:
				cell.textLabel.text = @"台灣近海";
				break;				
			case 6:
				cell.textLabel.text = @"三天潮汐";
				break;				
			case 7:
				cell.textLabel.text = @"天氣觀測雲圖";
				break;				
			default:
				break;
		}
		return cell;
	}
	else if (indexPath.section == 2) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NormalIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NormalIdentifier] autorelease];
		}
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		switch (indexPath.row) {
			case 0:
				cell.textLabel.text = NSLocalizedString(@"About", @"");
				break;
			default:
				break;
		}
		return cell;
	}
		
	return nil;

}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.section == 0) {
		NSDictionary *dictionary = [warningArray objectAtIndex:indexPath.row];
		TWOverviewViewController *controller = [[TWOverviewViewController alloc] init];
		[controller setText:[dictionary objectForKey:@"text"]];
		controller.title = [dictionary objectForKey:@"name"];
		[[TWWeatherAppDelegate sharedDelegate] pushViewController:controller animated:YES];
		[controller release];		
	}
	else if (indexPath.section == 1) {
		UITableViewController *controller = nil;
		if (indexPath.row == 0) {
			[[TWAPIBox sharedBox] fetchOverviewWithFormat:TWOverviewPlainFormat delegate:self userInfo:nil];
			isLoadingOverview = YES;
			[self.tableView reloadData];
			self.tableView.userInteractionEnabled = NO;
		}
		else if (indexPath.row == 1) {
			controller = [[TWForecastTableViewController alloc] initWithStyle:UITableViewStylePlain];
		}
		else if (indexPath.row == 2) {
			controller = [[TWWeekTableViewController alloc] initWithStyle:UITableViewStylePlain];
		}
		else if (indexPath.row == 3) {
			controller = [[TWWeekTravelTableViewController alloc] initWithStyle:UITableViewStylePlain];
		}
		else if (indexPath.row == 4) {
			controller = [[TWThreeDaySeaTableViewController alloc] initWithStyle:UITableViewStylePlain];
		}
		else if (indexPath.row == 5) {
			controller = [[TWNearSeaTableViewController alloc] initWithStyle:UITableViewStylePlain];
		}
		else if (indexPath.row == 6) {
			controller = [[TWTideTableViewController alloc] initWithStyle:UITableViewStylePlain];
		}
		else if (indexPath.row == 7) {
			controller = [[TWImageTableViewController alloc] initWithStyle:UITableViewStylePlain];
		}
		if (controller) {
			[[TWWeatherAppDelegate sharedDelegate] pushViewController:controller animated:YES];
			[controller release];
		}
	}
	else if (indexPath.section == 2) {
		UITableViewController *controller = nil;
		if (indexPath.row == 0) {
			controller = [[TWAboutViewController alloc] init];
		}
		if (controller) {
			[[TWWeatherAppDelegate sharedDelegate] pushViewController:controller animated:YES];
			[controller release];
		}		
	}
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 45.0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return 0.0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0) {
	}
	else if (section == 1) {
		return @"功能列表";
	}
	return nil;
}

- (void)APIBox:(TWAPIBox *)APIBox didFetchWarnings:(id)result userInfo:(id)userInfo
{
//	NSLog(@"result:%@", [result description]);
	if ([result isKindOfClass:[NSArray class]]) {
		[warningArray setArray:result];
	}
	[self.tableView reloadData];
}
- (void)APIBox:(TWAPIBox *)APIBox didFailedFetchWarningsWithError:(NSError *)error
{
	
}

- (void)APIBox:(TWAPIBox *)APIBox didFetchOverview:(NSString *)string userInfo:(id)userInfo
{
	isLoadingOverview = NO;
	[self.tableView reloadData];
	self.tableView.userInteractionEnabled = YES;
	TWOverviewViewController *controller = [[TWOverviewViewController alloc] init];
	[controller setText:string];
	[[TWWeatherAppDelegate sharedDelegate] pushViewController:controller animated:YES];
	[controller release];
}
- (void)APIBox:(TWAPIBox *)APIBox didFailedFetchOverviewWithError:(NSError *)error
{
	isLoadingOverview = NO;
	[self.tableView reloadData];
	self.tableView.userInteractionEnabled = YES;
	TWErrorViewController *controller = [[TWErrorViewController alloc] init];
	controller.error = error;
	[[TWWeatherAppDelegate sharedDelegate] pushViewController:controller animated:YES];
	[controller release];
}

@end
