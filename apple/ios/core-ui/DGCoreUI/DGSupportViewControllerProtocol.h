//
//  DGSupportViewControllerProtocol.h
//  DGCoreUI
//
//  Created by Mark Johnson on 9/5/12.
//  Copyright (c) 2012 Digital Generalists, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DGCoreUI/DGComponentTypeDefinitions.h>

@protocol DGSupportViewControllerProtocol <NSObject>

- (id) initWithHost:(UIViewController *)host;
- (id) initWithHost:(UIViewController *)host containerViewController:(UIViewController *)containerViewController;

- (void) attachToContainerViewController:(UIViewController *)containerViewController;

- (void) transitionToSupportViewMode:(DGSupportViewMode)newMode;

@optional

- (void) transitionToSupportViewMode:(DGSupportViewMode)newMode completion:(void(^)(void))completion;

@end
