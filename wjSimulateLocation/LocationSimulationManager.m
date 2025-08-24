//
//  LocationSimulationManager.m
//  wjSimulateLocation
//

#import "LocationSimulationManager.h"
#import <objc/runtime.h>

@interface LocationSimulationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) NSTimer *routeTimer;
@property (nonatomic, strong) NSArray<CLLocation *> *routeLocations;
@property (nonatomic, assign) NSInteger currentRouteIndex;
@property (nonatomic, strong) NSMutableArray<CLLocationManager *> *locationManagers;

@end

@implementation LocationSimulationManager

+ (instancetype)sharedManager {
    static LocationSimulationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LocationSimulationManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _simulationEnabled = YES;
        _locationManagers = [NSMutableArray array];
        [self setupMethodSwizzling];
        
        CLLocationCoordinate2D defaultCoordinate = CLLocationCoordinate2DMake(39.904200, 116.407396);
        _simulatedLocation = [[CLLocation alloc] initWithLatitude:defaultCoordinate.latitude 
                                                         longitude:defaultCoordinate.longitude];
    }
    return self;
}

- (void)setupMethodSwizzling {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [CLLocationManager class];
        
        SEL originalSelector = @selector(startUpdatingLocation);
        SEL swizzledSelector = @selector(swizzled_startUpdatingLocation);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class,
                                           originalSelector,
                                           method_getImplementation(swizzledMethod),
                                           method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                              swizzledSelector,
                              method_getImplementation(originalMethod),
                              method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
        SEL originalLocationSelector = @selector(location);
        SEL swizzledLocationSelector = @selector(swizzled_location);
        
        Method originalLocationMethod = class_getInstanceMethod(class, originalLocationSelector);
        Method swizzledLocationMethod = class_getInstanceMethod(class, swizzledLocationSelector);
        
        method_exchangeImplementations(originalLocationMethod, swizzledLocationMethod);
    });
}

- (void)updateSimulatedLocation:(CLLocationCoordinate2D)coordinate {
    self.simulatedLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude 
                                                         longitude:coordinate.longitude];
    [self notifyLocationManagers];
}

- (void)updateSimulatedLocationWithLatitude:(double)latitude longitude:(double)longitude {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    [self updateSimulatedLocation:coordinate];
}

- (void)startSimulatingRoute:(NSArray<CLLocation *> *)locations interval:(NSTimeInterval)interval {
    [self stopSimulation];
    
    self.routeLocations = locations;
    self.currentRouteIndex = 0;
    
    self.routeTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                        target:self
                                                      selector:@selector(updateRouteLocation)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)updateRouteLocation {
    if (self.currentRouteIndex < self.routeLocations.count) {
        self.simulatedLocation = self.routeLocations[self.currentRouteIndex];
        [self notifyLocationManagers];
        self.currentRouteIndex++;
    } else {
        self.currentRouteIndex = 0;
    }
}

- (void)stopSimulation {
    [self.routeTimer invalidate];
    self.routeTimer = nil;
}

- (void)notifyLocationManagers {
    for (CLLocationManager *manager in self.locationManagers) {
        if ([manager.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
            [manager.delegate locationManager:manager didUpdateLocations:@[self.simulatedLocation]];
        }
    }
}

- (void)registerLocationManager:(CLLocationManager *)manager {
    if (![self.locationManagers containsObject:manager]) {
        [self.locationManagers addObject:manager];
    }
}

@end

@implementation CLLocationManager (Swizzling)

- (void)swizzled_startUpdatingLocation {
    LocationSimulationManager *simulationManager = [LocationSimulationManager sharedManager];
    
    if (simulationManager.simulationEnabled) {
        [simulationManager registerLocationManager:self];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
                [self.delegate locationManager:self didUpdateLocations:@[simulationManager.simulatedLocation]];
            }
        });
    } else {
        [self swizzled_startUpdatingLocation];
    }
}

- (CLLocation *)swizzled_location {
    LocationSimulationManager *simulationManager = [LocationSimulationManager sharedManager];
    
    if (simulationManager.simulationEnabled && simulationManager.simulatedLocation) {
        return simulationManager.simulatedLocation;
    }
    
    return [self swizzled_location];
}

@end