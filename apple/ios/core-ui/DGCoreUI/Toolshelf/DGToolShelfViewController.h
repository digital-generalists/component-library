//
//  DGToolShelfViewController.h
//  DGCoreUI
//
//  Created by Mark Johnson on 8/31/12.
//  Copyright (c) 2012 Digital Generalists, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DGCoreUI/DGComponentTypeDefinitions.h>

#import <DGCoreUI/DGShelfViewController.h>
#import <DGCoreUI/DGShelfMenuDefinition.h>

#import <DGCoreUI/DGToolShelfUIStateManagerProtocol.h>
#import <DGCoreUI/DGNotificationObserver.h>

@protocol DGUIStateProtocol;

// A shelf of main menu buttons, each displaying a scrollable submenu of buttons. The menu structure, the
// buttons (including their targets and actions) and the visual styling are all supplied by the host.
//
// The shelf builds its own view hierarchy, with the main menu above the active submenu. The host is
// responsible for adding the shelf's view to its own hierarchy and sizing it. Initializing with the
// plain DGSupportViewControllerProtocol initializers produces an empty, unstyled shelf.
//
// The shelf posts UI_SAVE_UI_STATE whenever the active menu or a menu's scroll position changes. The host
// persists state by reading the shelf as a DGToolShelfUIStateManagerProtocol and passes it back through the
// state parameter at initialization to restore it.
@interface DGToolShelfViewController : DGShelfViewController<DGNotificationObserver, DGToolShelfUIStateManagerProtocol>

@property (readonly, copy, nonatomic) NSArray<DGShelfMenuDefinition *> *menus;
@property (readonly, strong, nonatomic) DGShelfMenuDefinition *favoritesMenu;

// menus are displayed from the main menu in order. favoritesMenu (optional) is displayed in place of the
// main menu and submenus when the shelf transitions to DGSupportViewModeFavorites.
- (id) initWithHost:(UIViewController *)host containerViewController:(UIViewController *)containerViewController menus:(NSArray<DGShelfMenuDefinition *> *)menus favoritesMenu:(DGShelfMenuDefinition *)favoritesMenu displayConfiguration:(DGToolShelfDisplayConfiguration)configuration state:(id<DGUIStateProtocol>)state;

// Swift can't import DGToolShelfDisplayConfiguration (a C struct holding object pointers), so this
// variant takes the configuration values individually.
- (id) initWithHost:(UIViewController *)host containerViewController:(UIViewController *)containerViewController menus:(NSArray<DGShelfMenuDefinition *> *)menus favoritesMenu:(DGShelfMenuDefinition *)favoritesMenu state:(id<DGUIStateProtocol>)state mainBackgroundColor:(UIColor *)mainBackgroundColor activeSubBackgroundColor:(UIColor *)activeSubBackgroundColor activeSubBorderColor:(UIColor *)activeSubBorderColor contentBackgroundColor:(UIColor *)contentBackgroundColor contentButtonBorderColor:(UIColor *)contentButtonBorderColor activeContentButtonBorderColor:(UIColor *)activeContentButtonBorderColor textColor:(UIColor *)textColor reservedLeftBorderWidth:(CGFloat)reservedLeftBorderWidth reservedRightBorderWidth:(CGFloat)reservedRightBorderWidth mainMenuNumberOfVisibleButtons:(NSInteger)mainMenuNumberOfVisibleButtons submenuNumberOfVisibleButtons:(NSInteger)submenuNumberOfVisibleButtons;

// Displays the submenu with the given name, as if its main menu button had been tapped.
- (void) displayMenuNamed:(NSString *)name;

// Draws (or clears) the active highlight on a button in one of the shelf's menus. The host calls this as
// its own model changes, e.g. when the selected tool changes.
- (void) applyActiveState:(bool)active toButton:(UIButton *)button;

// Re-applies the shelf's styling to the main menu buttons. Call after changing a main menu button's state.
- (void) applyStylingStatesToMenus;

@end
