//
//  DGPresentationCardCustomViewControllerProtocol.h
//  DGCoreUI
//
//  Created by Mark Johnson on 12/10/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DGCoreUI/DGComponentTypeDefinitions.h>

@protocol DGPresentationCardCustomViewControllerProtocol <NSObject>

- (id) initWithFrame:(CGRect)frame;

@optional

- (void) handleUserDismissal:(DGCardPresentationDismissAction)action;
- (void) handleDismissalAfterPresentationCloses:(DGCardPresentationDismissAction)action;

@end
