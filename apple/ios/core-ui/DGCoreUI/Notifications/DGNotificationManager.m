//
//  DGNotificationManager.m
//  DGCoreUI
//
//  Created by Mark Johnson on 11/16/12.
//  Copyright (c) 2012 Digital Generalists, LLC. All rights reserved.
//

#import "DGNotificationManager.h"

//#import "ApplicationMessages.h"
//#import "ModelMessages.h"
//#import "ViewControllerMessages.h"
//
#import "DGNotificationObserver.h"

@interface DGNotificationManager()

- (DGNotificationManager *) initForSingleton;
//
//// This shouldn't be used publicly because the  model and VC
//// messages have been so silo'd.
//- (void) registerForAllNotifications:(id<DGNotificationObserver>)observer;

@end

@implementation DGNotificationManager

+ (DGNotificationManager *)instance
{
    static DGNotificationManager *_instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[DGNotificationManager alloc] initForSingleton];
    });
    
    return _instance;
}

- (id) init
{
    @throw [NSException exceptionWithName:@"init is not supported for singleton classes" reason: @"class is a Singleton class" userInfo: nil];
}

- (id) initForSingleton
{
    self = [super init];
    if (self)
    {
        
    }
    return self;
}

- (void) registerObserver:(id<DGNotificationObserver>)observer forNotification:(NSString *)message
{
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(respondToMessage:) name:message object:nil];
}

- (void) registerObserver:(id<DGNotificationObserver>)observer forNotifications:(NSArray *)messages
{
    for (NSString *message in messages)
    {
        [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(respondToMessage:) name:message object:nil];
    }
}
//
//- (void) registerForAllNotifications:(id<DGNotificationObserver>)observer
//{
//    NSArray * messages = [NSArray arrayWithObjects:
//        ALL_APP_MESSAGES,
//        ALL_MODEL_MESSAGES,
//        ALL_UI_MESSAGES,
//        nil];
//    
//    [self registerObserver:observer forNotifications:messages];
//}

- (void) unregister:(id<DGNotificationObserver>)observer forNotification:(NSString *)message
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:message object:nil];
}

- (void) unregisterForAllNotifications:(id<DGNotificationObserver>)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

- (void) notify:(NSString *)message
{
    [self notify:message withData:nil];
}

- (void) notify:(NSString *)message withData:(id)data
{
    [[NSNotificationCenter defaultCenter] postNotificationName:message object:data];
}

- (bool) observer:(id<DGNotificationObserver>)observer shouldProcessNotification:(NSNotification *)notification
{
    bool result = true;
    
    if([[notification object] isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *params = [notification object];
        
        id notificationContext = [params objectForKey:APP_NOTIFICATION_PARAM_KEY_CONTEXT];
        
        if ((notificationContext != nil) && (![notificationContext isEqual:observer.notificationContext]))
        {
            if ([observer respondsToSelector:@selector(notificationContextForMessage:)])
            {
                if(![notificationContext isEqual:[observer notificationContextForMessage:[notification name]]])
                {
                    result = false;
                }
            }
            else
            {
                result = false;
            }
        }
    }
    
    return result;
}

@end
