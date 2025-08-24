//
//  GPXGenerator.m
//  wjSimulateLocation
//

#import "GPXGenerator.h"

@implementation GPXGenerator

+ (void)generateGPXFileWithLatitude:(double)latitude 
                          longitude:(double)longitude 
                               name:(NSString *)name
                           filePath:(NSString *)filePath {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSString *timeString = [formatter stringFromDate:[NSDate date]];
    
    NSString *gpxContent = [NSString stringWithFormat:
                            @"<?xml version=\"1.0\"?>\n"
                            @"<gpx version=\"1.1\" creator=\"Xcode\">\n"
                            @"    <wpt lat=\"%.6f\" lon=\"%.6f\">\n"
                            @"        <name>%@</name>\n"
                            @"        <time>%@</time>\n"
                            @"    </wpt>\n"
                            @"</gpx>",
                            latitude, longitude, name ?: @"位置", timeString];
    
    NSError *error;
    [gpxContent writeToFile:filePath 
                 atomically:YES 
                   encoding:NSUTF8StringEncoding 
                      error:&error];
    
    if (error) {
        NSLog(@"生成GPX文件失败: %@", error);
    } else {
        NSLog(@"GPX文件已生成: %@", filePath);
    }
}

+ (void)generateRouteGPXFileWithWaypoints:(NSArray<NSDictionary *> *)waypoints
                                  filePath:(NSString *)filePath {
    
    NSMutableString *gpxContent = [NSMutableString stringWithString:
                                   @"<?xml version=\"1.0\"?>\n"
                                   @"<gpx version=\"1.1\" creator=\"Xcode\">\n"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    NSDate *currentTime = [NSDate date];
    
    for (int i = 0; i < waypoints.count; i++) {
        NSDictionary *point = waypoints[i];
        double lat = [point[@"latitude"] doubleValue];
        double lon = [point[@"longitude"] doubleValue];
        NSString *name = point[@"name"] ?: [NSString stringWithFormat:@"位置%d", i+1];
        
        NSDate *pointTime = [currentTime dateByAddingTimeInterval:i * 300];
        NSString *timeString = [formatter stringFromDate:pointTime];
        
        [gpxContent appendFormat:
         @"    <wpt lat=\"%.6f\" lon=\"%.6f\">\n"
         @"        <name>%@</name>\n"
         @"        <time>%@</time>\n"
         @"    </wpt>\n",
         lat, lon, name, timeString];
    }
    
    [gpxContent appendString:@"</gpx>"];
    
    NSError *error;
    [gpxContent writeToFile:filePath 
                  atomically:YES 
                    encoding:NSUTF8StringEncoding 
                       error:&error];
    
    if (error) {
        NSLog(@"生成路线GPX文件失败: %@", error);
    } else {
        NSLog(@"路线GPX文件已生成: %@", filePath);
    }
}

@end