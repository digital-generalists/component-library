//
//  DGNotificationManager.h
//  DGCoreUI
//
//  Created by Mark Johnson on 11/16/12.
//  Copyright (c) 2012 Digital Generalists, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define APP_NOTIFICATION_PARAM_KEY_CONTEXT @"notificationContext"

#define APP_DATA_PARAM_KEY_DATA_OBJECT @"dataObject"

@protocol DGNotificationObserver;

@interface DGNotificationManager : NSObject

+ (DGNotificationManager *) instance;

- (bool) observer:(id<DGNotificationObserver>)observer shouldProcessNotification:(NSNotification *)notification;

- (void) registerObserver:(id<DGNotificationObserver>)observer forNotification:(NSString *)message;
- (void) registerObserver:(id<DGNotificationObserver>)observer forNotifications:(NSArray *)messages;

- (void) unregister:(id<DGNotificationObserver>)observer forNotification:(NSString *)message;
- (void) unregisterForAllNotifications:(id<DGNotificationObserver>)observer;

- (void) notify:(NSString *)message;
- (void) notify:(NSString *)message withData:(id)data;

@end
