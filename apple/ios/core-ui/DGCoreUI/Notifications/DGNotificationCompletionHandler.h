//
//  DGNotificationCompletionHandler.h
//  DGCoreUI
//
//  Created by Mark Johnson on 4/26/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DGNotificationCompletionHandler <NSObject>

- (void) notificationPostProcessing:(NSString *)notification;

@end
