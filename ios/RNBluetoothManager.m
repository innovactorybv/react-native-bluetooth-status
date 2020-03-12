//
//  RNBluetoothManager.m
//  taskuparkkiReactNativeWorkShop
//
//  Created by Juha Linnanen on 20/03/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "UIKit/UIKit.h"
#import "RNBluetoothManager.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


@implementation RNBluetoothManager
{
    bool hasListeners;
    NSString *stateName;
}

#pragma mark Initialization

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (void) initializeCentralManagerIfNeeded {
    if (self.centralManager == nil) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerOptionShowPowerAlertKey]];
    }
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(initialize) {
    [self initializeCentralManagerIfNeeded];
    [self centralManagerDidUpdateState:self.centralManager];
}

RCT_EXPORT_METHOD(setBluetoothState:(BOOL)enabled)
{
    if (@available(iOS 13.0, *)) {
        // Initiating a new CBCentralManager with the CBCentralManagerOptionShowPowerAlertKey will
        // allow the user to enable bluetooth via a system prompt. This only works on > iOS 13
        [[CBCentralManager alloc] initWithDelegate:nil queue:nil options: [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerOptionShowPowerAlertKey]];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        });
    }
}

- (NSString *) centralManagerStateToString: (int)state
{
    [self initializeCentralManagerIfNeeded];
    
    switch (state) {
        case CBCentralManagerStateUnknown:
            return @"unknown";
        case CBCentralManagerStateResetting:
            return @"resetting";
        case CBCentralManagerStateUnsupported:
            return @"unsupported";
        case CBCentralManagerStateUnauthorized:
            return @"unauthorized";
        case CBCentralManagerStatePoweredOff:
            return @"off";
        case CBCentralManagerStatePoweredOn:
            return @"on";
        default:
            return @"unknown";
    }

    return @"unknown";
}

-(void)startObserving {
    hasListeners = YES;
    [self initializeCentralManagerIfNeeded];
    [self sendEventWithName:@"bluetoothStatus" body:stateName];
}

-(void)stopObserving {
    hasListeners = NO;
    self.centralManager = nil;
}

- (void)addListener:(NSString *)eventName {
    [super addListener:eventName];
    [self sendEventWithName:@"bluetoothStatus" body:stateName];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    stateName = [self centralManagerStateToString:central.state];
    if (hasListeners) {
        [self sendEventWithName:@"bluetoothStatus" body:stateName];
    }
}

- (NSArray<NSString *> *)supportedEvents { return @[@"bluetoothStatus"]; }
@end


