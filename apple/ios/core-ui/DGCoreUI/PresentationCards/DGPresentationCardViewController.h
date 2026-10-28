//
//  DGPresentationCardViewController.h
//  DGCoreUI
//
//  Created by Mark Johnson on 11/21/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DGCoreUI/DGPresentationCardProtocol.h>

@interface DGPresentationCardViewController : UIViewController<DGPresentationCardProtocol>

- (id) initWithText:(NSString *)cardText textColor:(UIColor *)textColor;
- (id) initWithText:(NSString *)cardText textColor:(UIColor *)textColor image:(UIImage *)cardImage;
- (id) initWithText:(NSString *)cardText textColor:(UIColor *)textColor image:(UIImage *)cardImage highlightRegion:(CGRect)region;
- (id) initWithText:(NSString *)cardText textColor:(UIColor *)textColor image:(UIImage *)cardImage highlightRegion:(CGRect)region action:(NSString *)actionNotification;
- (id) initWithCustomView:(UIView *)view highlightRegion:(CGRect)region action:(NSString *)actionNotification;
- (id) initWithCustomViewController:(UIViewController *)viewController highlightRegion:(CGRect)region action:(NSString *)actionNotification;

@end
