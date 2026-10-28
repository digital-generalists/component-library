//
//  DGNotificationObserver.h
//  DGCoreUI
//
//  Created by Mark Johnson on 11/16/12.
//  Copyright (c) 2012 Digital Generalists, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DGNotification : NSNotification

@end

@protocol DGNotificationObserver <NSObject>

@property (readonly, strong, nonatomic) id notificationContext;

- (void) respondToMessage:(DGNotification *)context;

- (void) beginReceivingNotifications;
- (void) stopReceivingNotifications;


@optional

- (id) notificationContextForMessage:(NSString *)message;

@end

