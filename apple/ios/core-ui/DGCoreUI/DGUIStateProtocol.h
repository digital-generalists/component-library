//
//  DGUIStateProtocol.h
//  DGCoreUI
//
//  Created by Mark Johnson on 10/9/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DGUIStateManagerProtocol;

@protocol DGUIStateProtocol <NSObject, NSSecureCoding>

- (id) initWithStateManager:(id<DGUIStateManagerProtocol>)manager;
- (void) mergeWithStateManager:(id<DGUIStateManagerProtocol>)manager;

@end
