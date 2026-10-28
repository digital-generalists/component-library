//
//  DGMenuUIStateManagerProtocol.h
//  DGCoreUI
//
//  Created by Mark Johnson on 10/16/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DGCoreUI/DGUIStateManagerProtocol.h>

@protocol DGMenuUIStateManagerProtocol <DGUIStateManagerProtocol>

@property (nonatomic, readonly) CGPoint scrollOffset;

@end
