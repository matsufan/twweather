//
//  TWThreeDaySeaResultTableViewController.h
//  TWWeather
//
//  Created by zonble on 2009/08/01.
//

#import "FBConnect/FBConnect.h"


@interface TWThreeDaySeaResultTableViewController : UITableViewController 
{
	NSArray *forecastArray;
	NSString *publishTime;
}

@property (retain, nonatomic) NSArray *forecastArray;
@property (retain, nonatomic) NSString *publishTime;

@end
