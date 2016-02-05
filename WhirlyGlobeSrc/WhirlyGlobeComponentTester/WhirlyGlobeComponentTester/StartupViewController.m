/*
 *  StartupViewController.m
 *  WhirlyGlobeComponentTester
 *
 *  Created by Steve Gifford on 7/23/12.
 *  Copyright 2011-2013 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import "StartupViewController.h"
#import "ConfigViewController.h"

@interface StartupViewController ()

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation StartupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Map Type";
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor grayColor];
    self.tableView.separatorColor = [UIColor whiteColor];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.view.autoresizesSubviews = true;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.tableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

#pragma mark - Table Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Regular modes, and show/hide test
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
    {
        return MaplyNumTypes;
    } else {
        return 2;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
        
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"cell id";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.backgroundColor = [UIColor grayColor];
    }
    if(indexPath.section == 0)
    {
        switch (indexPath.row)
        {
            case MaplyGlobe:
                cell.textLabel.text = @"Globe (3D)";
                break;
            case MaplyGlobeWithElevation:
                cell.textLabel.text = @"Globe w/ Elevation (3D)";
                break;
            case Maply2DMap:
                cell.textLabel.text = @"Map (2D)";
                break;
            case Maply2DBNG:
                cell.textLabel.text = @"Map (2D) British National Grid";
                break;
            case Maply3DMap:
                cell.textLabel.text = @"Map (3D)";
                break;
            case MaplyGlobeScrollView:
                cell.textLabel.text = @"Globe - UIScrollView (3D)";
                break;
            case Maply2DScrollView:
                cell.textLabel.text = @"Map - UIScrollView (2D)";
                break;
            default:
                break;
        }
    } else if(indexPath.section == 1) {
        if(indexPath.row == 0) {
            cell.textLabel.text = @"Globe (3D), setup/teardown 10 times";
        } else if(indexPath.row == 1) {
            cell.textLabel.text = @"Map (2D), setup/teardown 10 times";
        }
    }
    return cell;
}

#pragma mark - Table Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
    {
        TestViewController *viewC = [[TestViewController alloc] initWithMapType:(int)indexPath.row];
        [self.navigationController pushViewController:viewC animated:YES];
    } else {
        MapType mapType;
        if(indexPath.row == 0)
        {
            mapType = MaplyGlobe;
        } else {
            mapType = Maply2DMap;
        }

        [self runSetupTeardownTest:mapType count:10 baselayer:nil
                  baseLayerOptions:@[ kMaplyTestBlank,
                                      kMaplyTestGeographyClass,
                                      kMaplyTestBlueMarble,
                                      kMaplyTestStamenWatercolor,
                                      kMaplyTestOSM,
                                      kMaplyTestMapBoxSat,
                                      kMaplyTestQuadTest,
                                      kMaplyTestNightAndDay
                                     ]];
    }
}


#pragma setup/teardown test

- (void)runSetupTeardownTest:(MapType)mapType
                       count:(NSInteger)count
                   baselayer:(NSString*)baseLayer
            baseLayerOptions:(NSArray<NSString*>*)baseLayerOptions
{
    if(!baseLayer) {
        baseLayer = baseLayerOptions[0];
    }
    NSLog(@"showing test view controller with base map type:%@", baseLayer);
    
    TestViewController *viewController = [[TestViewController alloc] initWithMapType:mapType];
    viewController.baseLayerSettingsOverride = @{
                                                 baseLayer: @YES
                                                 };
    [self presentViewController:viewController
                       animated:YES
                     completion:
     ^{
         NSLog(@"present complete");
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
             [self dismissViewControllerAnimated:YES
                                      completion:
              ^{
                  NSLog(@"dismis complete");
                  if(count - 1 > 0)
                  {
                      NSUInteger baseLayerIndex = [baseLayerOptions indexOfObject:baseLayer];
                      if(++baseLayerIndex == baseLayerOptions.count - 1)
                          baseLayerIndex = 0;
                      [self runSetupTeardownTest:mapType count:count - 1
                                       baselayer:baseLayerOptions[baseLayerIndex]
                                baseLayerOptions:baseLayerOptions];
                  }
              }];
         });
     }];
}

@end
