//
//  DGShelfMenuDefinition.h
//  DGCoreUI
//
//  Created by Mark Johnson on 10/25/26.
//  Copyright (c) 2026 Digital Generalists, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

// Describes one menu of the tool shelf: the main menu button that activates it and the buttons it
// contains. The host creates and configures all buttons (images, titles, targets and actions); the
// shelf only lays them out, styles them and switches between menus.
@interface DGShelfMenuDefinition : NSObject

// Unique within a shelf. Used to display the menu programmatically and to key its saved UI state.
@property (readonly, copy, nonatomic) NSString *name;

// The main menu button that displays this menu. The shelf attaches its own target to this button.
// Nil for a menu that is not reachable from the main menu (e.g. the favorites menu).
@property (readonly, strong, nonatomic) UIButton *menuButton;

@property (readonly, copy, nonatomic) NSArray<UIButton *> *buttons;

// Buttons for which a double tap is meaningful to the host. A double tap on any other button in
// the menu requests dismissal of the support UI (UI_DISMISS_SUPPORT_UI_REQUESTED).
@property (readonly, copy, nonatomic) NSArray<UIButton *> *buttonsIgnoringDoubleTap;

- (id) initWithName:(NSString *)name menuButton:(UIButton *)menuButton buttons:(NSArray<UIButton *> *)buttons;
- (id) initWithName:(NSString *)name menuButton:(UIButton *)menuButton buttons:(NSArray<UIButton *> *)buttons buttonsIgnoringDoubleTap:(NSArray<UIButton *> *)buttonsIgnoringDoubleTap;

@end
