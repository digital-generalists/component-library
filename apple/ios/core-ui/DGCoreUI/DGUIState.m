//
//  DGUIState.m
//  DGCoreUI
//
//  Created by Mark Johnson on 10/9/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import "DGUIState.h"

#import <DGCoreUI/DGComponentTypeDefinitions.h>

#import "DGMenuUIState.h"
#import "DGUIStateManagerProtocol.h"
#import "DGSupportUIStateManagerProtocol.h"

#define ENCODING_PROPERTY_SUPPORT_VIEW_MODE @"supportViewMode"
#define ENCODING_PROPERTY_SUPPORT_VIEW_MODE_VISIBLE @"supportViewModeVisible"
#define ENCODING_PROPERTY_TOOL_SHELF_MENU_BUTTON_INDEX @"menuButtonIndex"
#define ENCODING_PROPERTY_TOOL_SHELF_MENU_STATES @"menuStates"

@interface DGUIState()

@property (nonatomic, readwrite) DGSupportViewMode supportViewMode;
@property (nonatomic, readwrite) bool supportViewModeVisible;

@property (nonatomic, readwrite) NSUInteger menuButtonIndex;
@property (nonatomic, readwrite) NSDictionary *menuStates;

@end


@implementation DGUIState

@synthesize supportViewMode = _supportViewMode;
@synthesize supportViewModeVisible = _supportViewModeVisible;

@synthesize menuButtonIndex = _menuButtonIndex;
@synthesize menuStates = _menuStates;

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

- (void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:self.supportViewMode forKey:ENCODING_PROPERTY_SUPPORT_VIEW_MODE];
    [coder encodeBool:self.supportViewModeVisible forKey:ENCODING_PROPERTY_SUPPORT_VIEW_MODE_VISIBLE];
    [coder encodeInteger:self.menuButtonIndex forKey:ENCODING_PROPERTY_TOOL_SHELF_MENU_BUTTON_INDEX];
    [coder encodeObject:self.menuStates forKey:ENCODING_PROPERTY_TOOL_SHELF_MENU_STATES];
}

- (id) initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self)
    {
        _supportViewMode = (DGSupportViewMode)[decoder decodeIntegerForKey:ENCODING_PROPERTY_SUPPORT_VIEW_MODE];
        _supportViewModeVisible = [decoder decodeBoolForKey:ENCODING_PROPERTY_SUPPORT_VIEW_MODE_VISIBLE];
        _menuButtonIndex = [decoder decodeIntegerForKey:ENCODING_PROPERTY_TOOL_SHELF_MENU_BUTTON_INDEX];
        _menuStates = [decoder decodeDictionaryWithKeysOfClass:[NSString class] objectsOfClass:[DGMenuUIState class] forKey:ENCODING_PROPERTY_TOOL_SHELF_MENU_STATES];
    }
    return self;
}

- (void) mergeWithStateManager:(id<DGUIStateManagerProtocol>)manager
{
    if([manager conformsToProtocol:@protocol(DGSupportUIStateManagerProtocol)])
    {
        self.supportViewMode = ((id<DGSupportUIStateManagerProtocol>)manager).supportViewMode;
        self.supportViewModeVisible = ((id<DGSupportUIStateManagerProtocol>)manager).supportViewModeVisible;
    }
    if([manager conformsToProtocol:@protocol(DGToolShelfUIStateManagerProtocol)])
    {
        self.menuButtonIndex = ((id<DGToolShelfUIStateManagerProtocol>)manager).menuButtonIndex;
        self.menuStates =  [[NSDictionary alloc] initWithDictionary:((id<DGToolShelfUIStateManagerProtocol>)manager).menuStates];
    }
}

@end
