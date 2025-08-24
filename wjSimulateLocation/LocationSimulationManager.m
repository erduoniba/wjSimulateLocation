//
//  LocationSimulationManager.m
//  wjSimulateLocation
//

#import "LocationSimulationManager.h"
#import "GPXGenerator.h"
#import <objc/runtime.h>
#import <MapKit/MapKit.h>
#import <dlfcn.h>

@interface LocationSimulationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) NSTimer *routeTimer;
@property (nonatomic, strong) NSArray<CLLocation *> *routeLocations;
@property (nonatomic, assign) NSInteger currentRouteIndex;
@property (nonatomic, strong) NSMutableSet<CLLocationManager *> *locationManagers;
@property (nonatomic, strong) NSTimer *updateTimer;

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
        _locationManagers = [NSMutableSet set];
        [self setupMethodSwizzling];
        
        CLLocationCoordinate2D defaultCoordinate = CLLocationCoordinate2DMake(39.904200, 116.407396);
        _simulatedLocation = [[CLLocation alloc] initWithLatitude:defaultCoordinate.latitude 
                                                         longitude:defaultCoordinate.longitude];
        
        // 定期更新位置以确保地图刷新
        _updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                         target:self
                                                       selector:@selector(broadcastLocationUpdate)
                                                       userInfo:nil
                                                        repeats:YES];
    }
    return self;
}

- (void)setupMethodSwizzling {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [CLLocationManager class];
        
        // Hook startUpdatingLocation
        [self swizzleMethod:@selector(startUpdatingLocation) 
                withMethod:@selector(swizzled_startUpdatingLocation) 
                   inClass:class];
        
        // Hook stopUpdatingLocation
        [self swizzleMethod:@selector(stopUpdatingLocation) 
                withMethod:@selector(swizzled_stopUpdatingLocation) 
                   inClass:class];
        
        // Hook location属性
        [self swizzleMethod:@selector(location) 
                withMethod:@selector(swizzled_location) 
                   inClass:class];
        
        // Hook requestLocation
        [self swizzleMethod:@selector(requestLocation) 
                withMethod:@selector(swizzled_requestLocation) 
                   inClass:class];
        
        // Hook MKMapView的userLocation
        Class mapViewClass = [MKMapView class];
        [self swizzleMethod:@selector(userLocation) 
                withMethod:@selector(swizzled_userLocation) 
                   inClass:mapViewClass];
    });
}

- (void)swizzleMethod:(SEL)originalSelector withMethod:(SEL)swizzledSelector inClass:(Class)class {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    if (!originalMethod || !swizzledMethod) {
        return;
    }
    
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
}

- (void)updateSimulatedLocation:(CLLocationCoordinate2D)coordinate {
    self.simulatedLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude 
                                                         longitude:coordinate.longitude];
    [self notifyLocationManagers];
}

- (void)updateSimulatedLocationWithLatitude:(double)latitude longitude:(double)longitude {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    [self updateSimulatedLocation:coordinate];
    
    // 同时更新系统级位置
    [self updateSystemLocationWithLatitude:latitude longitude:longitude];
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
    
    // 发送通知以更新地图显示
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SimulatedLocationDidUpdate" 
                                                        object:nil 
                                                      userInfo:@{@"location": self.simulatedLocation}];
}

- (void)broadcastLocationUpdate {
    if (self.simulationEnabled && self.simulatedLocation) {
        [self notifyLocationManagers];
    }
}

#pragma mark - System Level Location Update

- (void)updateSystemLocationWithLatitude:(double)latitude longitude:(double)longitude {
    // 方法1: 动态更新GPX文件
    [self updateGPXFileWithLatitude:latitude longitude:longitude];
    
    // 方法2: 使用私有API
    [self setSystemSimulatedLocationWithLatitude:latitude longitude:longitude];
    
    // 方法3: 发送系统通知
    [self sendSystemLocationNotification:latitude longitude:longitude];
}

- (void)updateGPXFileWithLatitude:(double)latitude longitude:(double)longitude {
    // 获取当前正在使用的GPX文件路径
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *projectPath = [bundlePath stringByDeletingLastPathComponent];
    projectPath = [projectPath stringByDeletingLastPathComponent];
    NSString *gpxPath = [projectPath stringByAppendingPathComponent:@"wjSimulateLocation/wjSimulateLocation/Location.gpx"];
    
    // 生成新的GPX内容
    [GPXGenerator generateGPXFileWithLatitude:latitude 
                                     longitude:longitude 
                                          name:@"动态位置" 
                                      filePath:gpxPath];
    
    NSLog(@"已更新GPX文件: %@", gpxPath);
}

- (void)setSystemSimulatedLocationWithLatitude:(double)latitude longitude:(double)longitude {
    // 尝试使用CLSimulationManager私有API
    Class CLSimulationManager = NSClassFromString(@"CLSimulationManager");
    if (CLSimulationManager) {
        SEL sharedManagerSel = NSSelectorFromString(@"sharedManager");
        if ([CLSimulationManager respondsToSelector:sharedManagerSel]) {
            id manager = [CLSimulationManager performSelector:sharedManagerSel];
            
            if (manager) {
                // 清除旧位置
                SEL clearSel = NSSelectorFromString(@"clearSimulatedLocations");
                if ([manager respondsToSelector:clearSel]) {
                    [manager performSelector:clearSel];
                }
                
                // 添加新位置
                CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                SEL appendSel = NSSelectorFromString(@"appendSimulatedLocation:");
                if ([manager respondsToSelector:appendSel]) {
                    [manager performSelector:appendSel withObject:newLocation];
                }
                
                // 开始模拟
                SEL startSel = NSSelectorFromString(@"startLocationSimulation");
                if ([manager respondsToSelector:startSel]) {
                    [manager performSelector:startSel];
                }
                
                NSLog(@"已通过CLSimulationManager更新系统位置");
            }
        }
    }
}

- (void)sendSystemLocationNotification:(double)latitude longitude:(double)longitude {
    // 发送Darwin通知
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    
    // 准备位置数据
    NSDictionary *locationInfo = @{
        @"latitude": @(latitude),
        @"longitude": @(longitude),
        @"timestamp": @([[NSDate date] timeIntervalSince1970])
    };
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:locationInfo options:0 error:nil];
    NSString *locationString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // 发送多个可能的通知
    CFNotificationCenterPostNotification(center,
                                        CFSTR("com.apple.locationd.simulation.setlocation"),
                                        NULL,
                                        (__bridge CFDictionaryRef)@{@"location": locationString},
                                        kCFNotificationDeliverImmediately);
    
    CFNotificationCenterPostNotification(center,
                                        CFSTR("com.apple.CoreLocation.simulatedLocation"),
                                        NULL,
                                        (__bridge CFDictionaryRef)@{@"location": locationString},
                                        kCFNotificationDeliverImmediately);
    
    // 触发GPX重载
    CFNotificationCenterPostNotification(center,
                                        CFSTR("com.apple.locationd.reloadGPX"),
                                        NULL,
                                        NULL,
                                        kCFNotificationDeliverImmediately);
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

- (void)swizzled_stopUpdatingLocation {
    LocationSimulationManager *simulationManager = [LocationSimulationManager sharedManager];
    
    if (simulationManager.simulationEnabled) {
        [simulationManager.locationManagers removeObject:self];
    } else {
        [self swizzled_stopUpdatingLocation];
    }
}

- (void)swizzled_requestLocation {
    LocationSimulationManager *simulationManager = [LocationSimulationManager sharedManager];
    
    if (simulationManager.simulationEnabled) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
                [self.delegate locationManager:self didUpdateLocations:@[simulationManager.simulatedLocation]];
            }
        });
    } else {
        [self swizzled_requestLocation];
    }
}

@end

@implementation MKMapView (Swizzling)

- (MKUserLocation *)swizzled_userLocation {
    MKUserLocation *userLocation = [self swizzled_userLocation];
    
    LocationSimulationManager *simulationManager = [LocationSimulationManager sharedManager];
    if (simulationManager.simulationEnabled && simulationManager.simulatedLocation) {
        // MKUserLocation只支持设置location属性，不支持单独设置latitude/longitude
        @try {
            [userLocation setValue:simulationManager.simulatedLocation forKey:@"location"];
        } @catch (NSException *exception) {
            NSLog(@"无法更新MKUserLocation: %@", exception);
        }
    }
    
    return userLocation;
}

@end