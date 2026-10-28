//
//  PresentationCardTypes.h
//  DGCoreUI
//
//  Created by Mark Johnson on 7/25/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef majic_PresentationCardTypes_h
#define majic_PresentationCardTypes_h

#define UI_DEFAULT_PRESENTATION_CARD_WIDTH 280
#define UI_DEFAULT_PRESENTATION_CARD_HEIGHT 292

typedef enum
{
    DGSupportViewTypeToolshelf,
    DGSupportViewTypeContainerAccess
} DGSupportViewType;

typedef enum
{
    DGSupportViewModeDisabledBackground,
    DGSupportViewModeControl,
    DGSupportViewModeFavorites
} DGSupportViewMode;

typedef enum
{
    DGMenuTypeMain,
    DGMenuTypeSub
} DGMenuType;

typedef enum
{
    DGShelfBounceAnimationDirectionLeft,
    DGShelfBounceAnimationDirectionRight
} DGShelfBounceAnimationDirection;

typedef enum
{
    DGCardPresentationDismissActionAccept,
    DGCardPresentationDismissActionDecline,
    DGCardPresentationDismissActionCancel,
    DGCardPresentationDismissActionExternalLaunch
} DGCardPresentationDismissAction;

typedef enum
{
    DGCardPresentationButtonTypesDismiss,
    DGCardPresentationButtonTypesAcceptDecline,
    DGCardPresentationButtonTypesIgnore
} DGCardPresentationButtonTypes;

// Composite Parameter Keys

#define UI_CARD_PRESENTATION_DISMISSED @"cardPresentationDismissed"
#define UI_DISMISS_CARD_PRESENTATION @"dismissCardPresentation"
#define UI_SAVE_UI_STATE @"saveUIState"
#define UI_MENU_DOUBLE_TAPPED @"menuDoubleTapped"
#define UI_CONTROL_UI_REQUESTED @"controlUIRequested"
#define UI_FAVORITES_UI_REQUESTED @"favoritesUIRequested"
#define UI_CONTROL_UI_DEMANDED @"controlUIDemanded"
#define UI_FAVORITES_UI_DEMANDED @"favoritesUIDemanded"
#define UI_DISMISS_SUPPORT_UI_REQUESTED @"dismissSupportUIRequested"
#define UI_DISMISS_DATA_VIEW_CONTROLLER_EDIT_UI_REQUESTED @"dismissEditUIRequested"
#define UI_CURRENT_DATA_VIEW_CONTROLLER_CHANGED @"currentDataViewControllerChanged"
#define UI_MENU_DOUBLE_TAPPED @"menuDoubleTapped"
#define UI_HIGHLIGHT_POSITION_LABEL @"highlightPositionLabel"
#define UI_SUPPORT_UI_POSITIONED @"supportUIPositioned"

#define PRESENTATION_CARD_DISMISSAL_ACTION @"dismissalAction"

struct CF_SWIFT_SENDABLE DGPresentationDisplayConfiguration {
    UIColor *backgroundColor;
    UIColor *pageIndicatorTintColor;
    UIColor *currentPageIndicatorTintColor;
    UIColor *textColor;
    UIColor *highlightedTextColor;
    CGFloat topOffset;
    CGFloat statusBarHeight;
};
typedef struct CF_BOXABLE DGPresentationDisplayConfiguration DGPresentationDisplayConfiguration;

struct CF_SWIFT_SENDABLE DGToolShelfDisplayConfiguration {
    UIColor *mainBackgroundColor;
    UIColor *activeSubBackgroundColor;
    UIColor *activeSubBorderColor;
    UIColor *contentBackgroundColor;
    UIColor *contentButtonBorderColor;
    UIColor *activeContentButtonBorderColor;
    UIColor *textColor;
    CGFloat reservedLeftBorderWidth;
    CGFloat reservedRightBorderWidth;
    NSInteger mainMenuNumberOfVisibleButtons;
    NSInteger submenuNumberOfVisibleButtons;
};
typedef struct CF_BOXABLE DGToolShelfDisplayConfiguration DGToolShelfDisplayConfiguration;

#endif
