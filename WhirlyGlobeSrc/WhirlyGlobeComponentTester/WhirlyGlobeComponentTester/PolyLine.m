//
//  PolyLine.m
//  WhirlyGlobeComponentTester
//
//  Created by Jesse Crocker on 11/16/15.
//  Copyright © 2015 mousebird consulting. All rights reserved.
//

#import "PolyLine.h"
#import "WhirlyGlobeComponent.h"

@interface PolyLine ()

@property (nonatomic, strong, readwrite) NSArray * vectors;

@end

@implementation PolyLine

#define norm2(v)   dotproduct(v,v)        // norm2 = squared length of vector
#define norm(v)    sqrt(norm2(v))  // norm = length of vector
#define d2(u,v)    norm2(sub(u,v))      // distance squared = norm2 of difference
#define d(u,v)     norm(u-v)       // distance = norm of difference


- (instancetype)initWithCoordinates:(NSArray*)coordsArray
                             forMap:(MaplyBaseViewController*)map {
  self = [super init];
  if(self) {
    NSInteger count = [coordsArray count];
    CLLocationCoordinate2D *coords = calloc(count, sizeof(CLLocationCoordinate2D));
    for(int i = 0; i < count; i++) {
      NSArray *coord = coordsArray[i];
      coords[i] = CLLocationCoordinate2DMake([coord[1] floatValue], [coord[0] floatValue]);
    }
    self.vectors = [self generateVectors:coords count:count forMap:map];
    free(coords);
  }
  return self;
}


- (instancetype)initWithCoordinates:(CLLocationCoordinate2D*)coords
                              count:(NSUInteger)count
                             forMap:(MaplyBaseViewController*)map {
  self = [super init];
  if(self) {
    self.vectors = [self generateVectors:coords count:count forMap:map];
  }
  return self;
}

- (NSArray*)generateVectors:(CLLocationCoordinate2D*)coords
                      count:(NSUInteger)count
                     forMap:(MaplyBaseViewController*)map {
  NSMutableArray *vectors = [NSMutableArray array];
  
  int maxZoom = 19;
  int minZoom = 1;
  int zStride = 2;
  for (int z = minZoom; z <= maxZoom; z += zStride) {
    NSUInteger simpleLength = 0;
    CLLocationCoordinate2D* simplifiedCoords;
    
    BOOL needToFreeCoords = NO;
    if(z == maxZoom) {
      NSLog(@"Reached max zoom, not simplifying");
      simplifiedCoords = coords;
      simpleLength = count;
    } else {
      double simplifyTolerance = 1.0/(powf((double)z, 5.0)/32.0);
      simplifiedCoords = [PolyLine poly_simplify:coords
                                     arrayLength:count
                                   withTolerance:simplifyTolerance
                                withReturnLength:&simpleLength];
      NSLog(@"Simplified %lu to %lu tol %f zoom %i", (unsigned long)count, (unsigned long)simpleLength, simplifyTolerance, z);
      needToFreeCoords = YES;
    }
    
    MaplyCoordinate *maplyCoords = malloc(sizeof(MaplyCoordinate) * simpleLength);
    for(int i = 0; i < simpleLength; i++) {
      maplyCoords[i] = MaplyCoordinateMakeWithDegrees(simplifiedCoords[i].longitude,
                                                      simplifiedCoords[i].latitude);
    }
    if(needToFreeCoords) {
      free(simplifiedCoords);
    }
    
    BOOL done = simpleLength == count;//No simplification happened, so we dont need to make more levels
    NSDictionary *properties;
    if(done) {
      properties = @{
                     kMaplyMaxVis:@([self zoomToHeight:z forMap:map])
                     };
    } else if(z == minZoom) {
      properties = @{
                     kMaplyMinVis:@([self zoomToHeight:z + zStride forMap:map]),
                     };
    } else {
      properties = @{
                     kMaplyMaxVis:@([self zoomToHeight:z forMap:map]),
                     kMaplyMinVis:@([self zoomToHeight:z + zStride forMap:map]),
                     };
    }
    NSLog(@"%@", properties);
    MaplyVectorObject *vector = [[MaplyVectorObject alloc] initWithLineString:maplyCoords
                                                                    numCoords:(int)simpleLength
                                                                   attributes:properties];
    [vectors addObject:vector];
    
    free(maplyCoords);
    
    if(done) {
      break;
    }
  }
  
  return vectors;
}


#pragma mark - line simplification
double dotproduct(CLLocationCoordinate2D u, CLLocationCoordinate2D v) {
  return (u.longitude * v.longitude + u.latitude * v.latitude);
}

CLLocationCoordinate2D sub(CLLocationCoordinate2D u, CLLocationCoordinate2D v) {
  CLLocationCoordinate2D w = {u.latitude - v.latitude, u.longitude - v.longitude};
  return w;
}

int doDP2(CLLocationCoordinate2D* points, double tol, int j, int k, int* mk) {
  if (k <= j + 1) return 0;
  double maxd2 = 0;
  int maxi = 0;
  double tol2 = tol*tol;
  CLLocationCoordinate2D startPoint = points[j];
  CLLocationCoordinate2D endPoint = points[k];
  CLLocationCoordinate2D u = sub(endPoint, startPoint);
  double cu = dotproduct(u, u);
  
  for (int i = j+1; i < k; i++) {
    CLLocationCoordinate2D currentPoint = points[i];
    CLLocationCoordinate2D w = sub(currentPoint, startPoint);
    double cw = dotproduct(w, u);
    double dv2;
    if (cw <= 0) {
      dv2 = d2(currentPoint, startPoint);
    } else if (cu <= cw) {
      dv2 = d2(currentPoint, endPoint);
    } else {
      double b = cw / cu;
      CLLocationCoordinate2D Pb = {startPoint.latitude + b * u.latitude, startPoint.longitude + b * u.longitude};
      
      dv2 = d2(currentPoint, Pb);
    }
    
    if (dv2 <= maxd2) continue;
    maxi = i;
    maxd2 = dv2;
  }
  
  int cnt = 0;
  if (maxd2 > tol2) {
    if (mk[maxi] != 1) {
      mk[maxi] = 1;
      cnt = 1;
    }
    cnt += doDP2(points, tol, j, maxi, mk);
    cnt += doDP2(points, tol, maxi, k, mk);
  }
  return cnt;
}


+(CLLocationCoordinate2D*) poly_simplify:(CLLocationCoordinate2D*)V arrayLength:(NSUInteger)n withTolerance:(float) tol
                        withReturnLength:(NSUInteger*)returnLength
{
  if (n < 3) {
    CLLocationCoordinate2D *o = malloc(sizeof(CLLocationCoordinate2D) * n);
    for(int i = 0; i < n; i++) {
      o[i] = V[i];
    }
    *returnLength = n;
    return o;
  }
  int    i, k, pv;            // misc counters
  float  tol2 = tol * tol;       // tolerance squared
  
  int *nk = calloc(n, sizeof(int));
  nk[0] = nk[n-1] = 1;
  // STAGE 1.  Vertex Reduction within tolerance of prior vertex cluster
  for (i=1, k=2, pv=0; i<n-1; i++) {
    
    if (d2(V[i], V[pv]) < tol2)
      continue;
    nk[i] = 1;
    pv = i;
    k++;
  }
  
  CLLocationCoordinate2D *vt = malloc(sizeof(CLLocationCoordinate2D) * k);
  for (i=pv=0; i < n; i++) {
    if (nk[i] == 1) {
      vt[pv++] = V[i];
    }
  }
  free(nk);
  
  // STAGE 2.  Douglas-Peucker polyline simplification
  int *mk = calloc(k, sizeof(int));
  for(i=0;i<k;i++) mk[i] = 0;
  mk[0] = mk[k-1] = 1;       // mark the first and last vertices
  int cnt = 2 + doDP2(vt, tol, 0, k-1, mk );
  
  CLLocationCoordinate2D * sV = calloc(sizeof(CLLocationCoordinate2D), cnt + 1);
  for (i=0, pv=0; i<k; i++) {
    if (mk[i] == 1)
      sV[pv++] = vt[i];
  }
  CLLocationCoordinate2D sentinel =  {999, 999};
  sV[cnt] = sentinel;
  free(vt);
  free(mk);
  *returnLength = pv;
  return sV;         // m vertices in simplified polyline
}


#pragma mark - 
static int zoomCorrection = 0;
/**
 used to determine min/max vis for layers
 */
- (float)zoomToHeight:(float)zoom forMap:(MaplyBaseViewController*)map {
  CGFloat scale =  zoomToScale(zoom + zoomCorrection);
  float height = [map heightForMapScale:scale];
  // DDLogInfo(@"Zoom: %f+%d(%f) scale:%f height:%f", zoom, zoomCorrection, zoom + zoomCorrection, scale, height);
  return height;
}

//https://github.com/openstreetmap/mapnik-stylesheets/blob/master/zoom-to-scale.txt
double zoomToScale(float zoom) {
  double scale = 279541132.014;
  for(int i = 1; i < zoom; i++) {
    scale = scale / 2.0;
  }
  float fraction = fmodf(zoom, 1);
  if(fraction > 0.01) {
    scale += scale * fraction;
  }
  return scale;
}

@end
