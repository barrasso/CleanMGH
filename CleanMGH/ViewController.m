//
//  ViewController.m
//  CleanMGH
//
//  Created by Mark on 1/11/15.
//  Copyright (c) 2015 MEB. All rights reserved.
//

#import "ViewController.h"
#import "ESTBeaconManager.h"
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController () <ESTBeaconManagerDelegate>

// UI properties
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UIImageView *beaconImage;
@property (strong, nonatomic) IBOutlet UILabel *counterLabel;
@property (strong, nonatomic) IBOutlet UILabel *activityLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

// estimote beacon properties
@property (nonatomic, strong) ESTBeacon *beacon;
@property (nonatomic, strong) ESTBeaconManager  *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion   *beaconRegion;

@end

@implementation ViewController
{
    BOOL _isInsideRegion;
}

- (id)initWithBeacon:(ESTBeacon*)beacon
{
    self = [self init];
    if (self)
    {
        self.beacon = beacon;
    }
    return self;
}

#pragma mark - View Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /* setup estimote beacon manager */
    // create beacon manager instance
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    //self.beaconManager.avoidUnknownStateBeacons = YES;
    
    // request always authorization
    // Check location manager for iOS 8
    if ([self.beaconManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        [self.beaconManager requestAlwaysAuthorization];
    
    // hardcode blueberry beacon
    NSUUID *myUUID = [[NSUUID alloc] initWithUUIDString:@"b9407f30-f5f8-466e-aff9-25556b57fe6d"];
    NSNumber* major = @8799;
    NSNumber* minor = @48808;
    
    // setup beacon region
    self.beaconRegion = [[ESTBeaconRegion alloc]
                         initWithProximityUUID:myUUID
                         major:[major unsignedIntegerValue]
                         minor:[minor unsignedIntegerValue]
                         identifier:@"RegionIdentifier"];
    
    // start looking for estimote beacons in region
    // when beacon ranged beaconManager:didEnterRegion:
    // and beaconManager:didExitRegion: invoked
    [self.beaconManager startMonitoringForRegion:self.beaconRegion];
    [self.beaconManager requestStateForRegion:self.beaconRegion];
    
    // start looking for estimote beacons in region
    // when beacon ranged beaconManager:didRangeBeacons:inRegion: invoked
    [self.beaconManager startRangingBeaconsInRegion:self.beaconRegion];
    
    //In order to read beacon accelerometer we need to connect to it.
    self.beacon.delegate = self;
    [self.beacon connect];
    [self.activityIndicator startAnimating];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma - Location Monitoring Methods

- (void)sendEnterNotification
{
    if (!_isInsideRegion)
    {
        UILocalNotification *notice = [[UILocalNotification alloc] init];
        notice.soundName = UILocalNotificationDefaultSoundName;
        notice.alertBody= @"Inside beacon region";
        notice.alertAction = @"Open";
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
        
        _isInsideRegion = YES;
    }
}

- (void)sendExitNotification
{
    if (_isInsideRegion)
    {
        UILocalNotification *notice = [[UILocalNotification alloc] init];
        notice.soundName = UILocalNotificationDefaultSoundName;
        notice.alertBody = @"Outisde beacon region";
        notice.alertAction = @"Open";
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
        
        _isInsideRegion = NO;
    }
}

#pragma mark - ESTBeaconManager delegate

- (void)beaconManager:(ESTBeaconManager *)manager monitoringDidFailForRegion:(ESTBeaconRegion *)region withError:(NSError *)error
{
    UIAlertView* errorView = [[UIAlertView alloc]
    initWithTitle:@"Monitoring error"
    message:error.localizedDescription
    delegate:nil
    cancelButtonTitle:@"OK"
    otherButtonTitles:nil];
    
    [errorView show];
}

//- (void)beaconManager:(ESTBeaconManager *)manager didEnterRegion:(ESTBeaconRegion *)region
//{
//    [self sendEnterNotification];
//}
//
//- (void)beaconManager:(ESTBeaconManager *)manager didExitRegion:(ESTBeaconRegion *)region
//{
//    [self sendExitNotification];
//}

- (void)beaconManager:(ESTBeaconManager *)manager
     didRangeBeacons:(NSArray *)beacons
            inRegion:(ESTBeaconRegion *)region
{
    for (ESTBeacon *beacon in beacons) {
        NSLog(@"Region State: %ld",beacon.proximity);
        NSLog(@"RSSI Value: %li",(long)beacon.rssi);
        // calculate proximity state
        switch (beacon.proximity)
        {
            case CLProximityUnknown:
                self.locationLabel.text = @"Unknown";
                
                [self sendExitNotification];
                
                break;
            case CLProximityImmediate:
                self.locationLabel.text = @"Immediate";
                
                [self sendEnterNotification];
                
                break;
            case CLProximityNear:
                self.locationLabel.text = @"Near";
                
                [self sendEnterNotification];
                
                break;
            case CLProximityFar:
                self.locationLabel.text = @"Far";
                
                [self sendEnterNotification];
                
                break;
            default:
                break;
        }
    }
}

- (void)beaconConnectionDidSucceeded:(ESTBeacon *)beacon
{
    [self.activityIndicator stopAnimating];
    self.activityIndicator.alpha = 0.;
    self.activityLabel.text = @"Connected!";
    
    //After successful connection, we can read or reset accelerometer data.
    [self.beacon resetAccelerometerCountWithCompletion:^(unsigned short value, NSError *error) {
        
        NSLog(@"Error: %@", error);
        
        if (!error)
        {
            self.counterLabel.text = [NSString stringWithFormat:@"Beacon move count: %hu", value];
        }
        else
        {
            self.activityLabel.text = [NSString stringWithFormat:@"Error:%@", [error localizedDescription]];
            self.activityLabel.textColor = [UIColor redColor];
        }
        
    }];
}

- (void)beaconConnectionDidFail:(ESTBeacon *)beacon withError:(NSError *)error
{
    NSLog(@"Something went wrong. Beacon connection Did Fail. Error: %@", error);
    
    [self.activityIndicator stopAnimating];
    self.activityIndicator.alpha = 0.;
    
    self.activityLabel.text = @"Connection failed";
    self.activityLabel.textColor = [UIColor redColor];
    
    UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:@"Connection error"
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    
    [errorView show];
}

- (void)beacon:(ESTBeacon *)beacon accelerometerStateChanged:(BOOL)state
{
    //State is updated after beacon accelerometer was stabilised.
    if (state)
    {
        [self vibrateEffect];
    }
    else
    {
        [self readAccelerometerCount];
    }
}

#pragma mark - Other Methods

- (void)readAccelerometerCount
{
    [self.beacon readAccelerometerCountWithCompletion:^(NSNumber* value, NSError *error) {
        self.counterLabel.text = [NSString stringWithFormat:@"Hands Cleaned: %tu", [value integerValue]];
    }];
}

- (void)vibrateEffect
{
    if (self.beacon.isMoving && self.beacon.connectionStatus == ESTConnectionStatusConnected)
    {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        animation.duration = 0.6;
        animation.values = @[ @(-20), @(20), @(-20), @(20), @(-10), @(10), @(-5), @(5), @(0) ];
        [self.beaconImage.layer addAnimation:animation forKey:@"shake"];
        
        [self performSelector:@selector(vibrateEffect) withObject:nil afterDelay:0.6];
    }
}

@end
