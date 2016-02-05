//
//  SImpleTestViewController.m
//  WhirlyGlobeComponentTester
//
//  Created by Jesse Crocker on 2/5/16.
//  Copyright © 2016 mousebird consulting. All rights reserved.
//

#import "SImpleTestViewController.h"
#import <MaplyViewController.h>

@interface SImpleTestViewController () {
  MaplyViewController *mapViewC;
}

@end

@implementation SImpleTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  mapViewC = [[MaplyViewController alloc] initWithMapType:MaplyMapTypeFlat];
  mapViewC.viewWrap = true;
  mapViewC.doubleTapZoomGesture = true;
  mapViewC.twoFingerTapGesture = true;
  [self.view addSubview:mapViewC.view];
  mapViewC.view.frame = self.view.bounds;
  [self addChildViewController:mapViewC];
}

- (void)dealloc {
  NSLog(@"dealloc");
  [mapViewC willMoveToParentViewController:nil];
  [mapViewC.view removeFromSuperview];
  [mapViewC removeFromParentViewController];
  mapViewC = nil;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  mapViewC.height = 1.0;
  [mapViewC animateToPosition:MaplyCoordinateMakeWithDegrees(-122.4192, 37.7793) time:1.0];
}

@end
