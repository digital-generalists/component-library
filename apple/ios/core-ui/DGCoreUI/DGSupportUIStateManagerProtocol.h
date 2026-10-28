//
//  DGUIStateManagerProtocol.h
//  DGCoreUI
//
//  Created by Mark Johnson on 10/10/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DGCoreUI/DGComponentTypeDefinitions.h>
#import <DGCoreUI/DGUIStateManagerProtocol.h>

@protocol DGSupportUIStateManagerProtocol <DGUIStateManagerProtocol>

@property (nonatomic, readonly) DGSupportViewMode supportViewMode;
@property (nonatomic, readonly) bool supportViewModeVisible;

@end
