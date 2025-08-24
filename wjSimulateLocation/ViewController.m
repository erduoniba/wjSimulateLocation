//
//  ViewController.m
//  wjSimulateLocation
//
//  Created by gouzi on 2017/4/16.
//  Copyright © 2017年 wj. All rights reserved.
//

#import "ViewController.h"
#import "wjLocationTransform.h"
#import "GPXGenerator.h"
#import "LocationControlViewController.h"
#import "LocationSimulationManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化位置模拟管理器
    [LocationSimulationManager sharedManager];
    
    // 原有代码：坐标转换示例
    wjLocationTransform *gdLocation = [[wjLocationTransform alloc]initWithLatitude:39.02443 andLongitude:125.767166];
    wjLocationTransform *iosLocation = [gdLocation transformFromGDToGPS];
    NSLog(@"转化后iOS坐标传入到gpx文件中:%f, %f", iosLocation.latitude, iosLocation.longitude);
    
    // 添加按钮打开位置控制界面
    [self setupControlButton];
    
    // 动态生成单个位置的GPX文件
    [self generateSingleLocationGPX];
    
    // 动态生成路线GPX文件
    [self generateRouteGPX];
}

- (void)setupControlButton {
    UIButton *controlButton = [UIButton buttonWithType:UIButtonTypeSystem];
    controlButton.frame = CGRectMake(50, 100, self.view.frame.size.width - 100, 50);
    [controlButton setTitle:@"打开位置控制台" forState:UIControlStateNormal];
    controlButton.backgroundColor = [UIColor systemBlueColor];
    [controlButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    controlButton.layer.cornerRadius = 10;
    controlButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [controlButton addTarget:self action:@selector(openLocationControl) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:controlButton];
    
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 160, self.view.frame.size.width - 40, 100)];
    infoLabel.text = @"使用说明:\n1. 点击上方按钮打开控制台\n2. 可实时修改位置，无需重启\n3. 支持地图点击选择位置\n4. 支持路线模拟";
    infoLabel.numberOfLines = 0;
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.textColor = [UIColor systemGrayColor];
    [self.view addSubview:infoLabel];
}

- (void)openLocationControl {
    LocationControlViewController *controlVC = [[LocationControlViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controlVC];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - 动态生成GPX文件示例

- (void)generateSingleLocationGPX {
    // 示例：生成北京天安门的GPX文件
    // 高德坐标
    wjLocationTransform *gdLocation = [[wjLocationTransform alloc]initWithLatitude:39.907503 andLongitude:116.391239];
    // 转换为iOS坐标
    wjLocationTransform *iosLocation = [gdLocation transformFromGDToGPS];
    
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *gpxPath = [documentsPath stringByAppendingPathComponent:@"DynamicLocation.gpx"];
    
    [GPXGenerator generateGPXFileWithLatitude:iosLocation.latitude
                                    longitude:iosLocation.longitude
                                         name:@"天安门"
                                     filePath:gpxPath];
    
    NSLog(@"动态GPX文件已生成: %@", gpxPath);
}

- (void)generateRouteGPX {
    // 示例：生成一条路线（高德坐标需要转换）
    NSArray *gdPoints = @[
        @{@"latitude": @39.907503, @"longitude": @116.391239, @"name": @"天安门"},
        @{@"latitude": @39.915285, @"longitude": @116.397155, @"name": @"故宫"},
        @{@"latitude": @39.924435, @"longitude": @116.397449, @"name": @"景山公园"},
        @{@"latitude": @39.93318, @"longitude": @116.389595, @"name": @"北海公园"}
    ];
    
    NSMutableArray *iosWaypoints = [NSMutableArray array];
    
    for (NSDictionary *point in gdPoints) {
        double gdLat = [point[@"latitude"] doubleValue];
        double gdLon = [point[@"longitude"] doubleValue];
        
        wjLocationTransform *gdLocation = [[wjLocationTransform alloc]initWithLatitude:gdLat andLongitude:gdLon];
        wjLocationTransform *iosLocation = [gdLocation transformFromGDToGPS];
        
        [iosWaypoints addObject:@{
            @"latitude": @(iosLocation.latitude),
            @"longitude": @(iosLocation.longitude),
            @"name": point[@"name"]
        }];
    }
    
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *gpxPath = [documentsPath stringByAppendingPathComponent:@"DynamicRoute.gpx"];
    
    [GPXGenerator generateRouteGPXFileWithWaypoints:iosWaypoints filePath:gpxPath];
    
    NSLog(@"动态路线GPX文件已生成: %@", gpxPath);
}

#pragma mark - 运行时切换位置

- (void)switchToLocation:(NSString *)locationName {
    // 可以在运行时通过Xcode的Debug菜单切换位置
    // Debug -> Simulate Location -> 选择不同的GPX文件
    NSLog(@"请在Xcode的Debug菜单中选择: Simulate Location -> %@", locationName);
}



@end
