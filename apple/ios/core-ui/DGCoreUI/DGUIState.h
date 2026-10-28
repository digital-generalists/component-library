//
//  DGUIState.h
//  DGCoreUI
//
//  Created by Mark Johnson on 10/9/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DGCoreUI/DGUIStateProtocol.h>
#import <DGCoreUI/DGSupportUIStateManagerProtocol.h>
#import <DGCoreUI/DGToolShelfUIStateManagerProtocol.h>

@interface DGUIState : NSObject<DGUIStateProtocol, DGSupportUIStateManagerProtocol, DGToolShelfUIStateManagerProtocol>

@end
