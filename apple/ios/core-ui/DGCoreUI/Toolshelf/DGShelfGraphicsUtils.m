//
//  DGShelfGraphicsUtils.m
//  DGCoreUI
//
//  Created by Mark Johnson on 10/25/26.
//  Copyright (c) 2026 Digital Generalists, LLC. All rights reserved.
//

#import "DGShelfGraphicsUtils.h"

#define BORDER_SHADOW_WIDTH 1.5

@implementation DGShelfGraphicsUtils

+ (UIImage *) borderShadowImageForRect:(CGRect)rect sides:(DGShelfRectSides)sides color:(UIColor *)color
{
    return [self borderShadowImageForRect:rect sides:sides color:color excludingRegion:CGRectZero eraseColor:[UIColor clearColor]];
}

+ (UIImage *) borderShadowImageForRect:(CGRect)rect sides:(DGShelfRectSides)sides color:(UIColor *)color excludingRegion:(CGRect)exclusionRegion eraseColor:(UIColor *)eraseColor
{
    if (CGRectIsEmpty(rect))
    {
        return nil;
    }

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.opaque = false;
    format.scale = 0.0f;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:rect.size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext)
    {
        CGContextRef context = rendererContext.CGContext;

        CGContextSetLineWidth(context, BORDER_SHADOW_WIDTH);
        CGContextSetStrokeColorWithColor(context, color.CGColor);

        CGContextBeginPath(context);

        if (sides & DGShelfRectSidesTop)
        {
            CGContextMoveToPoint(context, ceil(rect.origin.x), ceil(rect.origin.y));
            CGContextAddLineToPoint(context, ceil(rect.origin.x + rect.size.width), ceil(rect.origin.y));
        }
        if (sides & DGShelfRectSidesLeft)
        {
            CGContextMoveToPoint(context, ceil(rect.origin.x), ceil(rect.origin.y));
            CGContextAddLineToPoint(context, ceil(rect.origin.x), ceil(rect.origin.y + rect.size.height));
        }
        if (sides & DGShelfRectSidesBottom)
        {
            CGContextMoveToPoint(context, ceil(rect.origin.x), ceil(rect.origin.y + rect.size.height));
            CGContextAddLineToPoint(context, ceil(rect.origin.x + rect.size.width), ceil(rect.origin.y + rect.size.height));
        }
        if (sides & DGShelfRectSidesRight)
        {
            CGContextMoveToPoint(context, ceil(rect.origin.x + rect.size.width), ceil(rect.origin.y));
            CGContextAddLineToPoint(context, ceil(rect.origin.x + rect.size.width), ceil(rect.origin.y + rect.size.height));
        }

        CGContextStrokePath(context);

        if (!CGRectIsEmpty(exclusionRegion))
        {
            CGRect region = CGRectMake((exclusionRegion.origin.x + BORDER_SHADOW_WIDTH), exclusionRegion.origin.y, (exclusionRegion.size.width - (2.0 * BORDER_SHADOW_WIDTH)), exclusionRegion.size.height);
            CGContextSetLineWidth(context, (BORDER_SHADOW_WIDTH * 1.5));
            CGContextSetStrokeColorWithColor(context, eraseColor.CGColor);
            CGContextSetFillColorWithColor(context, eraseColor.CGColor);
            CGContextAddRect(context, region);
            CGContextFillRect(context, region);
            CGContextStrokeRect(context, region);
        }
    }];
}

// The rotation, in radians, the interface has already been given relative to portrait. An interface in
// UIInterfaceOrientationLandscapeRight corresponds to a device in UIDeviceOrientationLandscapeLeft.
static CGFloat InterfaceAngle(UIInterfaceOrientation orientation)
{
    switch (orientation)
    {
        case UIInterfaceOrientationPortraitUpsideDown:
            return M_PI;
        case UIInterfaceOrientationLandscapeRight:
            return M_PI_2;
        case UIInterfaceOrientationLandscapeLeft:
            return -M_PI_2;
        default:
            return 0.0;
    }
}

+ (void) rotateToDeviceOrientationContentsOfView:(UIView *)view interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    CGFloat angle = 0.0;
    switch ([UIDevice currentDevice].orientation)
    {
        case UIDeviceOrientationPortrait:
            angle = 0.0;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIDeviceOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
        case UIDeviceOrientationLandscapeRight:
            angle = -M_PI_2;
            break;
        default:
            // Face up, face down and unknown have no "up", so the icons return to upright.
            view.transform = CGAffineTransformIdentity;
            return;
    }

    // The interface may already be rotated to match the device. Only the remaining difference is applied,
    // so the icons look upright however the device is held and whether or not the interface rotates.
    angle = angle - InterfaceAngle(interfaceOrientation);
    while (angle > M_PI)
    {
        angle -= (2.0 * M_PI);
    }
    while (angle <= -M_PI)
    {
        angle += (2.0 * M_PI);
    }
    view.transform = CGAffineTransformMakeRotation(angle);
}

@end
