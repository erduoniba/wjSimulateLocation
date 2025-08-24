//
//  LocationSimulationManager.h
//  wjSimulateLocation
//
//  运行时动态位置模拟管理器
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationSimulationManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) BOOL simulationEnabled;
@property (nonatomic, strong) CLLocation *simulatedLocation;

- (void)updateSimulatedLocation:(CLLocationCoordinate2D)coordinate;
- (void)updateSimulatedLocationWithLatitude:(double)latitude longitude:(double)longitude;
- (void)startSimulatingRoute:(NSArray<CLLocation *> *)locations interval:(NSTimeInterval)interval;
- (void)stopSimulation;

@end