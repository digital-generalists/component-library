//
//  DGMenuUIState.m
//  DGCoreUI
//
//  Created by Mark Johnson on 10/16/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DGMenuUIState.h"

#define ENCODING_PROPERTY_SCROLL_OFFSET @"scrollOffset"

@interface DGMenuUIState()

@property (nonatomic, readwrite) CGPoint scrollOffset;

@end


@implementation DGMenuUIState

@synthesize scrollOffset = _scrollOffset;

+ (bool) supportsSecureCoding
{
    return true;
}

- (id) initWithStateManager:(id<DGUIStateManagerProtocol>)manager
{
    self = [super init];
    if (self)
    {
        [self mergeWithStateManager:manager];
    }
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder
{
    [coder encodeObject:NSStringFromCGPoint(self.scrollOffset) forKey:ENCODING_PROPERTY_SCROLL_OFFSET];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
{
    self = [super init];
    if (self)
    {
        // Older models persisted scrollOffset as an NSValue; newer ones use an NSString.
        // Decode both to support seamless loading of older models.
        id result = [coder decodeObjectOfClasses:[NSSet setWithObjects:NSString.class, NSValue.class, nil] forKey:ENCODING_PROPERTY_SCROLL_OFFSET];
        if ([result isKindOfClass:[NSString class]])
        {
            _scrollOffset = CGPointFromString(result);
        }
        else if ([result isKindOfClass:[NSValue class]])
        {
            _scrollOffset = [(NSValue *)result CGPointValue];
        }
    }
    return self;
}

- (void) mergeWithStateManager:(id<DGUIStateManagerProtocol>)manager
{
    if([manager conformsToProtocol:@protocol(DGMenuUIStateManagerProtocol)])
    {
        self.scrollOffset = ((id<DGMenuUIStateManagerProtocol>)manager).scrollOffset;
    }
}

@end
