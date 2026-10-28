//
//  DGNotificationAwareModelProtocol.h
//  DGCoreUI
//
//  Created by Mark Johnson on 8/12/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DGNotificationAwareModelProtocol <NSObject>

- (void) beginReceivingNotifications;
- (void) stopReceivingNotifications;

@end
