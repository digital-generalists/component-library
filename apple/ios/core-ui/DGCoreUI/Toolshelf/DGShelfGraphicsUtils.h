//
//  DGShelfGraphicsUtils.h
//  DGCoreUI
//
//  Created by Mark Johnson on 10/25/26.
//  Copyright (c) 2026 Digital Generalists, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, DGShelfRectSides)
{
    DGShelfRectSidesTop = 1 << 0,
    DGShelfRectSidesLeft = 1 << 1,
    DGShelfRectSidesRight = 1 << 2,
    DGShelfRectSidesBottom = 1 << 3
};

// Internal drawing helpers for the tool shelf. All colors are supplied by the caller (from the injected
// DGToolShelfDisplayConfiguration); nothing here is themed.
@interface DGShelfGraphicsUtils : NSObject

// Strokes a line along the requested sides of the rect. The lines run along the rect's edges, so half of
// each line's width falls outside the image.
+ (UIImage *) borderShadowImageForRect:(CGRect)rect sides:(DGShelfRectSides)sides color:(UIColor *)color;

// As above, then fills and strokes the exclusion region (in the image's coordinate space) with eraseColor,
// covering the border where it passes behind the region. Used to visually join the active main menu
// button to the submenu below it. An empty exclusion region is ignored.
+ (UIImage *) borderShadowImageForRect:(CGRect)rect sides:(DGShelfRectSides)sides color:(UIColor *)color excludingRegion:(CGRect)exclusionRegion eraseColor:(UIColor *)eraseColor;

// Rotates the view so its contents appear upright however the device is held. The interface orientation is
// the orientation the view's interface is currently laid out in: with a portrait-locked interface the icons
// counter-rotate by the full device angle, and with an interface that rotates along with the device they
// stay as they are. Face up, face down and unknown device orientations return the view to upright.
+ (void) rotateToDeviceOrientationContentsOfView:(UIView *)view interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

@end
