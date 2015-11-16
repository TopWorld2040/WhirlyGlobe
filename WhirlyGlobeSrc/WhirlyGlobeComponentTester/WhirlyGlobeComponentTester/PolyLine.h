//
//  PolyLine.h
//  WhirlyGlobeComponentTester
//
//  Created by Jesse Crocker on 11/16/15.
//  Copyright © 2015 mousebird consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class MaplyBaseViewController;

@interface PolyLine : NSObject

- (instancetype)initWithCoordinates:(NSArray*)coords
                             forMap:(MaplyBaseViewController*)map;

- (instancetype)initWithCoordinates:(CLLocationCoordinate2D*)coords
                              count:(NSUInteger)count
                             forMap:(MaplyBaseViewController*)map;

@property (nonatomic, readonly) NSArray *vectors;

@end
