//
//  GPXGenerator.h
//  wjSimulateLocation
//
//  动态生成和更新GPX文件的工具类
//

#import <Foundation/Foundation.h>

@interface GPXGenerator : NSObject

+ (void)generateGPXFileWithLatitude:(double)latitude 
                          longitude:(double)longitude 
                               name:(NSString *)name
                           filePath:(NSString *)filePath;

+ (void)generateRouteGPXFileWithWaypoints:(NSArray<NSDictionary *> *)waypoints
                                  filePath:(NSString *)filePath;

@end