//
//  DGPresentationCardProtocol.h
//  DGCoreUI
//
//  Created by Mark Johnson on 11/21/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DGCoreUI/DGComponentTypeDefinitions.h>

@protocol DGPresentationCardProtocol <NSObject>

@property (readonly, strong, nonatomic) NSString *cardText;
@property (readonly, strong, nonatomic) UIImage *cardImage;
@property (readonly, nonatomic) CGRect highlightRegion;
@property (readonly, strong, nonatomic) NSString *action;

+ (id) emptyCard;

- (bool) isCardEmpty;

- (void) cardBecameActive;

- (void) handleUserDismissal:(DGCardPresentationDismissAction)action;

- (void) handleDismissalAfterPresentationCloses:(DGCardPresentationDismissAction)action;

@end
