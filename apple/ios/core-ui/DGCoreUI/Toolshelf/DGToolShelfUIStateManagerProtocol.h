//
//  DGToolShelfUIStateManagerProtocol.h
//  DGCoreUI
//
//  Created by Mark Johnson on 10/12/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DGCoreUI/DGUIStateManagerProtocol.h>

@protocol DGToolShelfUIStateManagerProtocol <DGUIStateManagerProtocol>

@property (nonatomic, readonly) NSUInteger menuButtonIndex;
@property (nonatomic, readonly) NSDictionary *menuStates;

@end
