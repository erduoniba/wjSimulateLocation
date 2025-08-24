//
//  LocationControlViewController.m
//  wjSimulateLocation
//

#import "LocationControlViewController.h"
#import "LocationSimulationManager.h"
#import "wjLocationTransform.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface LocationControlViewController () <UITextFieldDelegate, CLLocationManagerDelegate, MKMapViewDelegate>

@property (nonatomic, strong) UITextField *latitudeField;
@property (nonatomic, strong) UITextField *longitudeField;
@property (nonatomic, strong) UISegmentedControl *coordinateTypeControl;
@property (nonatomic, strong) UIButton *updateButton;
@property (nonatomic, strong) UISwitch *simulationSwitch;
@property (nonatomic, strong) UILabel *currentLocationLabel;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) UIButton *presetBeijingButton;
@property (nonatomic, strong) UIButton *presetShanghaiButton;
@property (nonatomic, strong) UIButton *presetGuangzhouButton;
@property (nonatomic, strong) UIButton *startRouteButton;

@end

@implementation LocationControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"位置模拟控制";
    
    [self setupUI];
    [self setupLocationManager];
    [self updateCurrentLocationDisplay];
}

- (void)setupUI {
    CGFloat padding = 20;
    CGFloat currentY = 100;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, currentY, self.view.frame.size.width - 2*padding, 30)];
    titleLabel.text = @"动态位置模拟控制台";
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];
    currentY += 40;
    
    UILabel *switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, currentY, 100, 30)];
    switchLabel.text = @"启用模拟:";
    [self.view addSubview:switchLabel];
    
    self.simulationSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(120, currentY, 80, 30)];
    self.simulationSwitch.on = [LocationSimulationManager sharedManager].simulationEnabled;
    [self.simulationSwitch addTarget:self action:@selector(simulationSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.simulationSwitch];
    currentY += 40;
    
    self.coordinateTypeControl = [[UISegmentedControl alloc] initWithItems:@[@"WGS-84(iOS)", @"GCJ-02(高德)", @"BD-09(百度)"]];
    self.coordinateTypeControl.frame = CGRectMake(padding, currentY, self.view.frame.size.width - 2*padding, 35);
    self.coordinateTypeControl.selectedSegmentIndex = 1;
    [self.view addSubview:self.coordinateTypeControl];
    currentY += 45;
    
    UILabel *latLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, currentY, 60, 30)];
    latLabel.text = @"纬度:";
    [self.view addSubview:latLabel];
    
    self.latitudeField = [[UITextField alloc] initWithFrame:CGRectMake(80, currentY, self.view.frame.size.width - 100, 30)];
    self.latitudeField.borderStyle = UITextBorderStyleRoundedRect;
    self.latitudeField.placeholder = @"输入纬度 (如: 39.904200)";
    self.latitudeField.keyboardType = UIKeyboardTypeDecimalPad;
    self.latitudeField.delegate = self;
    [self.view addSubview:self.latitudeField];
    currentY += 40;
    
    UILabel *lonLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, currentY, 60, 30)];
    lonLabel.text = @"经度:";
    [self.view addSubview:lonLabel];
    
    self.longitudeField = [[UITextField alloc] initWithFrame:CGRectMake(80, currentY, self.view.frame.size.width - 100, 30)];
    self.longitudeField.borderStyle = UITextBorderStyleRoundedRect;
    self.longitudeField.placeholder = @"输入经度 (如: 116.407396)";
    self.longitudeField.keyboardType = UIKeyboardTypeDecimalPad;
    self.longitudeField.delegate = self;
    [self.view addSubview:self.longitudeField];
    currentY += 40;
    
    self.updateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.updateButton.frame = CGRectMake(padding, currentY, self.view.frame.size.width - 2*padding, 40);
    [self.updateButton setTitle:@"更新位置" forState:UIControlStateNormal];
    self.updateButton.backgroundColor = [UIColor systemBlueColor];
    [self.updateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.updateButton.layer.cornerRadius = 8;
    [self.updateButton addTarget:self action:@selector(updateLocationTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.updateButton];
    currentY += 50;
    
    UILabel *presetLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, currentY, self.view.frame.size.width - 2*padding, 25)];
    presetLabel.text = @"快速预设位置:";
    presetLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:presetLabel];
    currentY += 30;
    
    CGFloat buttonWidth = (self.view.frame.size.width - 4*padding) / 3;
    
    self.presetBeijingButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.presetBeijingButton.frame = CGRectMake(padding, currentY, buttonWidth, 35);
    [self.presetBeijingButton setTitle:@"北京" forState:UIControlStateNormal];
    self.presetBeijingButton.backgroundColor = [UIColor systemGrayColor];
    [self.presetBeijingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.presetBeijingButton.layer.cornerRadius = 5;
    [self.presetBeijingButton addTarget:self action:@selector(presetBeijingTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.presetBeijingButton];
    
    self.presetShanghaiButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.presetShanghaiButton.frame = CGRectMake(padding*2 + buttonWidth, currentY, buttonWidth, 35);
    [self.presetShanghaiButton setTitle:@"上海" forState:UIControlStateNormal];
    self.presetShanghaiButton.backgroundColor = [UIColor systemGrayColor];
    [self.presetShanghaiButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.presetShanghaiButton.layer.cornerRadius = 5;
    [self.presetShanghaiButton addTarget:self action:@selector(presetShanghaiTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.presetShanghaiButton];
    
    self.presetGuangzhouButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.presetGuangzhouButton.frame = CGRectMake(padding*3 + buttonWidth*2, currentY, buttonWidth, 35);
    [self.presetGuangzhouButton setTitle:@"广州" forState:UIControlStateNormal];
    self.presetGuangzhouButton.backgroundColor = [UIColor systemGrayColor];
    [self.presetGuangzhouButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.presetGuangzhouButton.layer.cornerRadius = 5;
    [self.presetGuangzhouButton addTarget:self action:@selector(presetGuangzhouTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.presetGuangzhouButton];
    currentY += 45;
    
    self.startRouteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.startRouteButton.frame = CGRectMake(padding, currentY, self.view.frame.size.width - 2*padding, 35);
    [self.startRouteButton setTitle:@"开始模拟路线" forState:UIControlStateNormal];
    self.startRouteButton.backgroundColor = [UIColor systemGreenColor];
    [self.startRouteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.startRouteButton.layer.cornerRadius = 5;
    [self.startRouteButton addTarget:self action:@selector(startRouteTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startRouteButton];
    currentY += 45;
    
    self.currentLocationLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, currentY, self.view.frame.size.width - 2*padding, 60)];
    self.currentLocationLabel.numberOfLines = 3;
    self.currentLocationLabel.font = [UIFont systemFontOfSize:12];
    self.currentLocationLabel.textColor = [UIColor systemGrayColor];
    [self.view addSubview:self.currentLocationLabel];
    currentY += 70;
    
    CGFloat mapHeight = self.view.frame.size.height - currentY - 50;
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, currentY, self.view.frame.size.width, mapHeight)];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    [self.view addSubview:self.mapView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMapTap:)];
    [self.mapView addGestureRecognizer:tapGesture];
}

- (void)setupLocationManager {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (void)simulationSwitchChanged:(UISwitch *)sender {
    [LocationSimulationManager sharedManager].simulationEnabled = sender.on;
    [self updateCurrentLocationDisplay];
}

- (void)updateLocationTapped {
    [self.view endEditing:YES];
    
    double latitude = [self.latitudeField.text doubleValue];
    double longitude = [self.longitudeField.text doubleValue];
    
    if (latitude == 0 || longitude == 0) {
        [self showAlert:@"请输入有效的经纬度"];
        return;
    }
    
    NSInteger selectedIndex = self.coordinateTypeControl.selectedSegmentIndex;
    
    if (selectedIndex == 1) {
        wjLocationTransform *gdLocation = [[wjLocationTransform alloc] initWithLatitude:latitude andLongitude:longitude];
        wjLocationTransform *iosLocation = [gdLocation transformFromGDToGPS];
        latitude = iosLocation.latitude;
        longitude = iosLocation.longitude;
    } else if (selectedIndex == 2) {
        wjLocationTransform *bdLocation = [[wjLocationTransform alloc] initWithLatitude:latitude andLongitude:longitude];
        wjLocationTransform *iosLocation = [bdLocation transformFromBDToGPS];
        latitude = iosLocation.latitude;
        longitude = iosLocation.longitude;
    }
    
    [[LocationSimulationManager sharedManager] updateSimulatedLocationWithLatitude:latitude longitude:longitude];
    
    [self updateCurrentLocationDisplay];
    [self centerMapOnLocation:CLLocationCoordinate2DMake(latitude, longitude)];
    
    [self showAlert:@"位置已更新"];
}

- (void)presetBeijingTapped {
    self.coordinateTypeControl.selectedSegmentIndex = 1;
    self.latitudeField.text = @"39.904200";
    self.longitudeField.text = @"116.407396";
    [self updateLocationTapped];
}

- (void)presetShanghaiTapped {
    self.coordinateTypeControl.selectedSegmentIndex = 1;
    self.latitudeField.text = @"31.230416";
    self.longitudeField.text = @"121.473701";
    [self updateLocationTapped];
}

- (void)presetGuangzhouTapped {
    self.coordinateTypeControl.selectedSegmentIndex = 1;
    self.latitudeField.text = @"23.129110";
    self.longitudeField.text = @"113.264360";
    [self updateLocationTapped];
}

- (void)startRouteTapped {
    NSArray *gdPoints = @[
        @[@39.904200, @116.407396],
        @[@39.915285, @116.397155],
        @[@39.924435, @116.397449],
        @[@39.93318, @116.389595]
    ];
    
    NSMutableArray *locations = [NSMutableArray array];
    for (NSArray *point in gdPoints) {
        double lat = [point[0] doubleValue];
        double lon = [point[1] doubleValue];
        
        wjLocationTransform *gdLocation = [[wjLocationTransform alloc] initWithLatitude:lat andLongitude:lon];
        wjLocationTransform *iosLocation = [gdLocation transformFromGDToGPS];
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:iosLocation.latitude longitude:iosLocation.longitude];
        [locations addObject:location];
    }
    
    [[LocationSimulationManager sharedManager] startSimulatingRoute:locations interval:3.0];
    
    [self showAlert:@"开始模拟路线移动"];
}

- (void)handleMapTap:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.mapView];
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    
    self.coordinateTypeControl.selectedSegmentIndex = 0;
    self.latitudeField.text = [NSString stringWithFormat:@"%.6f", coordinate.latitude];
    self.longitudeField.text = [NSString stringWithFormat:@"%.6f", coordinate.longitude];
    
    [self updateLocationTapped];
}

- (void)centerMapOnLocation:(CLLocationCoordinate2D)coordinate {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
    [self.mapView setRegion:region animated:YES];
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = coordinate;
    annotation.title = @"模拟位置";
    [self.mapView addAnnotation:annotation];
}

- (void)updateCurrentLocationDisplay {
    CLLocation *location = [LocationSimulationManager sharedManager].simulatedLocation;
    if (location) {
        self.currentLocationLabel.text = [NSString stringWithFormat:
                                         @"当前模拟位置:\n纬度: %.6f\n经度: %.6f",
                                         location.coordinate.latitude,
                                         location.coordinate.longitude];
    }
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [self updateCurrentLocationDisplay];
    if (locations.firstObject) {
        [self centerMapOnLocation:locations.firstObject.coordinate];
    }
}

@end