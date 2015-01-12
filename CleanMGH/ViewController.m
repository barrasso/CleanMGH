//
//  ViewController.m
//  CleanMGH
//
//  Created by Mark on 1/11/15.
//  Copyright (c) 2015 MEB. All rights reserved.
//

#import "ViewController.h"
#import "ESTBeaconManager.h"

@interface ViewController () <ESTBeaconManagerDelegate>

// estimote beacon properties
@property (nonatomic, strong) ESTBeaconManager  *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion   *beaconRegion;

@end

@implementation ViewController
{
    BOOL _isInsideRegion;
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
    }
    
    _isInsideRegion = YES;
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
    }
    
    _isInsideRegion = NO;
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

- (void)beaconManager:(ESTBeaconManager *)manager didEnterRegion:(ESTBeaconRegion *)region
{
    [self sendEnterNotification];
}

- (void)beaconManager:(ESTBeaconManager *)manager didExitRegion:(ESTBeaconRegion *)region
{
    [self sendExitNotification];
}

- (void)beaconManager:(ESTBeaconManager *)manager
     didRangeBeacons:(NSArray *)beacons
            inRegion:(ESTBeaconRegion *)region
{
    for (ESTBeacon *beacon in beacons) {
        NSLog(@"Region State: %ld",beacon.proximity);
        
        // calculate proximity state
        switch (beacon.proximity)
        {
            case CLProximityUnknown:
                self.regionLabel.text = @"Unknown";
                
                [self sendExitNotification];
                _isInsideRegion = NO;
                
                break;
            case CLProximityImmediate:
                self.regionLabel.text = @"Immediate";
                
                [self sendEnterNotification];
                _isInsideRegion = YES;
                
                break;
            case CLProximityNear:
                self.regionLabel.text = @"Near";
                
                [self sendEnterNotification];
                _isInsideRegion = YES;
                
                break;
            case CLProximityFar:
                self.regionLabel.text = @"Far";
                
                [self sendEnterNotification];
                _isInsideRegion = YES;
                
                break;
            default:
                break;
        }
    }
}

@end
