//
//  DGCardPresentationViewController.h
//  DGCoreUI
//
//  Created by Mark Johnson on 11/18/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DGCoreUI/DGSupportViewControllerProtocol.h>
#import <DGCoreUI/DGNotificationObserver.h>
#import <DGCoreUI/DGComponentTypeDefinitions.h>

@interface DGCardPresentationViewController : UIViewController<DGSupportViewControllerProtocol, DGNotificationObserver, UIScrollViewDelegate>

@property (readonly, nonatomic) UIViewController *host;

- (id) initWithHost:(UIViewController *)host presentationCards:(NSArray *)cards displayConfiguration:(DGPresentationDisplayConfiguration)configuration;
- (id) initWithHost:(UIViewController *)host presentationCards:(NSArray *)cards displayConfiguration:(DGPresentationDisplayConfiguration)configuration buttonTypes:(DGCardPresentationButtonTypes)buttons;

// Swift can't import DGPresentationDisplayConfiguration (a C struct holding object pointers), so this
// variant takes the configuration values individually.
- (id) initWithHost:(UIViewController *)host presentationCards:(NSArray *)cards backgroundColor:(UIColor *)backgroundColor pageIndicatorTintColor:(UIColor *)pageIndicatorTintColor currentPageIndicatorTintColor:(UIColor *)currentPageIndicatorTintColor textColor:(UIColor *)textColor highlightedTextColor:(UIColor *)highlightedTextColor topOffset:(CGFloat)topOffset statusBarHeight:(CGFloat)statusBarHeight buttonTypes:(DGCardPresentationButtonTypes)buttons;

@end
