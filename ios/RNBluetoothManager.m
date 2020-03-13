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

- (BOOL)hasBluetoothPermission
{
    if (@available(iOS 13.0, *)) {
        return [[CBManager new] authorization] > CBManagerAuthorizationDenied;
    }
    return YES;
}

- (BOOL)isBluetoothDenied
{
    if (@available(iOS 13.0, *)) {
        return [[CBManager new] authorization] == CBManagerAuthorizationDenied;
    }
    return NO;
}

- (void)openSettings
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    });
}

- (NSString *) centralManagerStateToString: (CBManagerState)state
{
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

- (void) initializeCentralManagerIfNeeded {
    #if TARGET_OS_SIMULATOR
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    return
    #endif
    
    // Only instantiate CBCentralManager when bluetooth permissions are available otherwise the permission
    // prompt will be immediately presented after instatiating CBCentralManager.
    // setBluetoothState can be used for this purpose.
    if (@available(iOS 13.0, *) && ![self hasBluetoothPermission]) {
        stateName = [self centralManagerStateToString:CBManagerStateUnauthorized];
        return;
    }


    if (self.centralManager == nil) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerOptionShowPowerAlertKey]];
    }
}

RCT_EXPORT_MODULE();



RCT_EXPORT_METHOD(setBluetoothState:(BOOL)enabled)
{
    if ([self isBluetoothDenied]) {
        // iOS >= 13 only: open app settings to grant denied bluetooth access
        [self openSettings];
        return;
    } else if (@available(iOS 13.0, *)) {
        // Initiating a new CBCentralManager with the CBCentralManagerOptionShowPowerAlertKey will
        // allow the user to enable bluetooth via a system prompt. This only works on >= iOS 13
        CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options: [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerOptionShowPowerAlertKey]];
        if (hasListeners) {
            // Previsouly we might have skipped assigning centralManager due to the fact we skipped instantiating
            // CBCentralManager because the authorization was CBManagerStateUnauthorized. We are still
            // interested to receive the status changes now we prompted the user for permissions.
            self.centralManager = centralManager;
        }
    } else {
        // iOS 12 and lower we can only open settings to enable bluetooth
        [self openSettings];
    }
}

-(void)startObserving {
    hasListeners = YES;
    [self initializeCentralManagerIfNeeded];
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


