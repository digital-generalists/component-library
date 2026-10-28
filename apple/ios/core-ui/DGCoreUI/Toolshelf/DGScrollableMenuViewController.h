//
//  DGScrollableMenuViewController.h
//  DGCoreUI
//
//  Created by Mark Johnson on 1/17/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DGCoreUI/DGComponentTypeDefinitions.h>

#import <DGCoreUI/DGMenuUIStateManagerProtocol.h>

@protocol DGUIStateProtocol;

@interface DGScrollableMenuViewController : UIViewController<UIScrollViewDelegate, DGMenuUIStateManagerProtocol>

@property (readonly, nonatomic) NSString *name;

- (id) initWithButtons:(NSArray *)buttons withNumberVisible:(NSInteger)numberVisible asType:(DGMenuType)type withName:(NSString *)name withState:(id<DGUIStateProtocol>)state displayConfiguration:(DGToolShelfDisplayConfiguration)configuration;

- (void) applyActiveStateToMenuButton:(UIButton *)button isActive:(bool)active;

- (void) rotateIconsToDeviceOrientationWithAnimation:(bool)animate interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

- (void) updateBorderToExcludeRegion:(CGRect)exclusionRegion;

@end
