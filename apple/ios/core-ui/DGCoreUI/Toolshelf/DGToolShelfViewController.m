//
//  DGToolShelfViewController.m
//  DGCoreUI
//
//  Created by Mark Johnson on 8/31/12.
//  Copyright (c) 2012 Digital Generalists, LLC. All rights reserved.
//

#import "QuartzCore/QuartzCore.h"

#import "DGToolShelfViewController.h"

#import <DGCoreUI/DGComponentTypeDefinitions.h>
#import <DGCoreUI/DGNotificationManager.h>

#import "DGScrollableMenuViewController.h"
#import "DGShelfGraphicsUtils.h"

#import "DGToolShelfUIStateManagerProtocol.h"
#import "DGUIStateProtocol.h"
#import "DGMenuUIState.h"

#define SHELF_DEFAULT_MAINMENU_NUMBER_VISIBLE_BUTTONS 6
#define SHELF_DEFAULT_SUBMENU_NUMBER_VISIBLE_BUTTONS 7

// Height of each of the main and active menu rows when the host has not yet sized the shelf.
#define SHELF_DEFAULT_MENU_ROW_HEIGHT 44.0

#define SHELF_MENU_NAME_MAIN @"mainMenu"

@interface DGToolShelfViewController ()

@property (readwrite, copy, nonatomic) NSArray<DGShelfMenuDefinition *> *menus;
@property (readwrite, strong, nonatomic) DGShelfMenuDefinition *favoritesMenu;

@property (nonatomic, strong) UIViewController *associatedContainerViewController;

@property (nonatomic) DGToolShelfDisplayConfiguration displayConfiguration;
@property (nonatomic, strong) id<DGUIStateProtocol> savedState;

@property (nonatomic, strong) UIView *mainMenuViewContainer;
@property (nonatomic, strong) UIView *activeMenuViewContainer;

@property (nonatomic, strong) UIButton *activeMainMenuButton;
@property (nonatomic, strong) DGScrollableMenuViewController *activeMenuViewController;

@property (nonatomic, strong) DGScrollableMenuViewController *mainMenuViewController;
@property (nonatomic, strong) DGScrollableMenuViewController *favoritesMenuViewController;

// Submenu view controllers in the same order as menus, and keyed by menu name.
@property (nonatomic, strong) NSArray *submenuViewControllers;
@property (nonatomic, strong) NSDictionary *submenuViewControllersByName;

// Main menu buttons of the menus that have one, in menu order.
@property (nonatomic, strong) NSArray *mainMenuButtons;

@property (nonatomic) DGSupportViewMode supportViewMode;

- (void) mainMenuButtonClicked:(id)sender;
- (void) displayMenu:(DGShelfMenuDefinition *)menu;

@end


@implementation DGToolShelfViewController

@synthesize menus = _menus;
@synthesize favoritesMenu = _favoritesMenu;

@synthesize associatedContainerViewController = _associatedContainerViewController;

@synthesize displayConfiguration = _displayConfiguration;
@synthesize savedState = _savedState;

@synthesize mainMenuViewContainer = _mainMenuViewContainer;
@synthesize activeMenuViewContainer = _activeMenuViewContainer;

@synthesize activeMainMenuButton = _activeMainMenuButton;
@synthesize activeMenuViewController = _activeMenuViewController;

@synthesize mainMenuViewController = _mainMenuViewController;
@synthesize favoritesMenuViewController = _favoritesMenuViewController;

@synthesize submenuViewControllers = _submenuViewControllers;
@synthesize submenuViewControllersByName = _submenuViewControllersByName;

@synthesize mainMenuButtons = _mainMenuButtons;

@synthesize supportViewMode = _supportViewMode;

- (id) initWithHost:(UIViewController *)host
{
    return [self initWithHost:host containerViewController:host];
}

- (id) initWithHost:(UIViewController *)host containerViewController:(UIViewController *)containerViewController
{
    DGToolShelfDisplayConfiguration configuration;
    memset((void*)&configuration, 0, sizeof(configuration));

    return [self initWithHost:host containerViewController:containerViewController menus:nil favoritesMenu:nil displayConfiguration:configuration state:nil];
}

- (id) initWithHost:(UIViewController *)host containerViewController:(UIViewController *)containerViewController menus:(NSArray<DGShelfMenuDefinition *> *)menus favoritesMenu:(DGShelfMenuDefinition *)favoritesMenu displayConfiguration:(DGToolShelfDisplayConfiguration)configuration state:(id<DGUIStateProtocol>)state
{
    self = [super initWithHost:host];
    if (self)
    {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

        assert(containerViewController != nil);

        self.associatedContainerViewController = containerViewController;

        self.supportViewMode = DGSupportViewModeControl;

        // A visible button count of zero would make the buttons unlayoutable.
        if (configuration.mainMenuNumberOfVisibleButtons <= 0)
        {
            configuration.mainMenuNumberOfVisibleButtons = SHELF_DEFAULT_MAINMENU_NUMBER_VISIBLE_BUTTONS;
        }
        if (configuration.submenuNumberOfVisibleButtons <= 0)
        {
            configuration.submenuNumberOfVisibleButtons = SHELF_DEFAULT_SUBMENU_NUMBER_VISIBLE_BUTTONS;
        }
        self.displayConfiguration = configuration;

        self.menus = (menus ? menus : @[]);
        self.favoritesMenu = favoritesMenu;
        self.savedState = state;
    }
    return self;
}

- (id) initWithHost:(UIViewController *)host containerViewController:(UIViewController *)containerViewController menus:(NSArray<DGShelfMenuDefinition *> *)menus favoritesMenu:(DGShelfMenuDefinition *)favoritesMenu state:(id<DGUIStateProtocol>)state mainBackgroundColor:(UIColor *)mainBackgroundColor activeSubBackgroundColor:(UIColor *)activeSubBackgroundColor activeSubBorderColor:(UIColor *)activeSubBorderColor contentBackgroundColor:(UIColor *)contentBackgroundColor contentButtonBorderColor:(UIColor *)contentButtonBorderColor activeContentButtonBorderColor:(UIColor *)activeContentButtonBorderColor textColor:(UIColor *)textColor reservedLeftBorderWidth:(CGFloat)reservedLeftBorderWidth reservedRightBorderWidth:(CGFloat)reservedRightBorderWidth mainMenuNumberOfVisibleButtons:(NSInteger)mainMenuNumberOfVisibleButtons submenuNumberOfVisibleButtons:(NSInteger)submenuNumberOfVisibleButtons
{
    DGToolShelfDisplayConfiguration configuration;
    configuration.mainBackgroundColor = mainBackgroundColor;
    configuration.activeSubBackgroundColor = activeSubBackgroundColor;
    configuration.activeSubBorderColor = activeSubBorderColor;
    configuration.contentBackgroundColor = contentBackgroundColor;
    configuration.contentButtonBorderColor = contentButtonBorderColor;
    configuration.activeContentButtonBorderColor = activeContentButtonBorderColor;
    configuration.textColor = textColor;
    configuration.reservedLeftBorderWidth = reservedLeftBorderWidth;
    configuration.reservedRightBorderWidth = reservedRightBorderWidth;
    configuration.mainMenuNumberOfVisibleButtons = mainMenuNumberOfVisibleButtons;
    configuration.submenuNumberOfVisibleButtons = submenuNumberOfVisibleButtons;

    return [self initWithHost:host containerViewController:containerViewController menus:menus favoritesMenu:favoritesMenu displayConfiguration:configuration state:state];
}

- (void) dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void) attachToContainerViewController:(UIViewController *)containerViewController
{
    assert(containerViewController != nil);
    self.associatedContainerViewController = containerViewController;
}

- (void) loadView
{
    UIView *rootView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.width, (SHELF_DEFAULT_MENU_ROW_HEIGHT * 2.0))];
    rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.view = rootView;

    self.mainMenuViewContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.mainMenuViewContainer.backgroundColor = self.displayConfiguration.mainBackgroundColor;
    [rootView addSubview:self.mainMenuViewContainer];

    self.activeMenuViewContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.activeMenuViewContainer.backgroundColor = self.displayConfiguration.activeSubBackgroundColor;
    [rootView addSubview:self.activeMenuViewContainer];

    [self layoutMenuContainers];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSMutableArray *mainMenuButtons = [NSMutableArray arrayWithCapacity:self.menus.count];
    NSMutableArray *submenuViewControllers = [NSMutableArray arrayWithCapacity:self.menus.count];
    NSMutableDictionary *submenuViewControllersByName = [NSMutableDictionary dictionaryWithCapacity:self.menus.count];

    for (DGShelfMenuDefinition *menu in self.menus)
    {
        DGScrollableMenuViewController *submenuViewController = [self menuViewControllerForDefinition:menu numberVisible:self.displayConfiguration.submenuNumberOfVisibleButtons];
        [submenuViewControllers addObject:submenuViewController];
        [submenuViewControllersByName setObject:submenuViewController forKey:menu.name];

        if (menu.menuButton)
        {
            [menu.menuButton addTarget:self action:@selector(mainMenuButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [mainMenuButtons addObject:menu.menuButton];
        }
    }
    self.mainMenuButtons = [NSArray arrayWithArray:mainMenuButtons];
    self.submenuViewControllers = [NSArray arrayWithArray:submenuViewControllers];
    self.submenuViewControllersByName = [NSDictionary dictionaryWithDictionary:submenuViewControllersByName];

    self.mainMenuViewController = [[DGScrollableMenuViewController alloc] initWithButtons:self.mainMenuButtons withNumberVisible:self.displayConfiguration.mainMenuNumberOfVisibleButtons asType:DGMenuTypeMain withName:SHELF_MENU_NAME_MAIN withState:self.savedState displayConfiguration:self.displayConfiguration];
    self.mainMenuViewController.view.frame = [self mainMenuFrame];
    [self.mainMenuViewContainer addSubview:self.mainMenuViewController.view];

    if (self.favoritesMenu)
    {
        // Leave room for the overflow shuttle buttons when the favorites don't all fit.
        NSInteger numberOfVisibleButtons = self.displayConfiguration.mainMenuNumberOfVisibleButtons;
        if (self.favoritesMenu.buttons.count > numberOfVisibleButtons)
        {
            numberOfVisibleButtons = numberOfVisibleButtons - 1;
        }
        self.favoritesMenuViewController = [self menuViewControllerForDefinition:self.favoritesMenu numberVisible:numberOfVisibleButtons];
    }

    DGShelfMenuDefinition *initialMenu = self.menus.firstObject;
    if ([self.savedState conformsToProtocol:@protocol(DGToolShelfUIStateManagerProtocol)])
    {
        NSUInteger savedIndex = ((id<DGToolShelfUIStateManagerProtocol>)self.savedState).menuButtonIndex;
        if (savedIndex < self.mainMenuButtons.count)
        {
            initialMenu = [self menuForMainMenuButton:[self.mainMenuButtons objectAtIndex:savedIndex]];
        }
    }
    if (initialMenu)
    {
        [self displayMenu:initialMenu];
    }
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self layoutMenuContainers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self beginReceivingNotifications];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self stopReceivingNotifications];
}

- (DGScrollableMenuViewController *) menuViewControllerForDefinition:(DGShelfMenuDefinition *)menu numberVisible:(NSInteger)numberVisible
{
    return [[DGScrollableMenuViewController alloc] initWithButtons:menu.buttons withNumberVisible:numberVisible asType:DGMenuTypeSub withName:menu.name withState:self.savedState displayConfiguration:self.displayConfiguration];
}

- (DGShelfMenuDefinition *) menuForMainMenuButton:(UIButton *)button
{
    for (DGShelfMenuDefinition *menu in self.menus)
    {
        if (menu.menuButton == button)
        {
            return menu;
        }
    }
    return nil;
}

#pragma mark - Layout

// The main menu sits directly above the active submenu, each taking half of the shelf.
- (void) layoutMenuContainers
{
    CGRect bounds = self.view.bounds;
    CGFloat rowHeight = floor(bounds.size.height / 2.0);

    self.mainMenuViewContainer.frame = CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, rowHeight);
    self.activeMenuViewContainer.frame = CGRectMake(bounds.origin.x, bounds.origin.y + rowHeight, bounds.size.width, bounds.size.height - rowHeight);

    self.mainMenuViewController.view.frame = [self mainMenuFrame];
    if (self.supportViewMode == DGSupportViewModeFavorites)
    {
        self.favoritesMenuViewController.view.frame = [self favoritesMenuFrame];
    }
    else
    {
        self.activeMenuViewController.view.frame = self.activeMenuViewContainer.bounds;
    }
}

- (CGRect) insetFrameInContainer:(UIView *)container
{
    return CGRectMake(self.displayConfiguration.reservedLeftBorderWidth, container.bounds.origin.y, (container.bounds.size.width - (self.displayConfiguration.reservedLeftBorderWidth + self.displayConfiguration.reservedRightBorderWidth)), container.bounds.size.height);
}

- (CGRect) mainMenuFrame
{
    return [self insetFrameInContainer:self.mainMenuViewContainer];
}

- (CGRect) favoritesMenuFrame
{
    return [self insetFrameInContainer:self.activeMenuViewContainer];
}

#pragma mark - Notifications

- (id) notificationContext
{
    return self.associatedContainerViewController;
}

- (void) beginReceivingNotifications
{
    [[DGNotificationManager instance] unregisterForAllNotifications:self];
    [[DGNotificationManager instance] registerObserver:self forNotifications:[NSArray arrayWithObjects:UI_MENU_DOUBLE_TAPPED, UIDeviceOrientationDidChangeNotification, nil]];
}

- (void) stopReceivingNotifications
{
    [[DGNotificationManager instance] unregisterForAllNotifications:self];
}

- (bool) isViewTopmostInActiveMenuContainer:(UIView *)view
{
    if (!view)
    {
        return false;
    }
    return ([self.activeMenuViewContainer.subviews indexOfObject:view] == ([self.activeMenuViewContainer.subviews count] - 1));
}

- (bool) buttonIgnoresDoubleTap:(UIButton *)button
{
    NSMutableArray *menus = [NSMutableArray arrayWithArray:self.menus];
    if (self.favoritesMenu)
    {
        [menus addObject:self.favoritesMenu];
    }

    for (DGShelfMenuDefinition *menu in menus)
    {
        if ([menu.buttonsIgnoringDoubleTap containsObject:button])
        {
            return true;
        }
    }
    return false;
}

- (void) respondToMessage:(DGNotification *)context
{
    if (![[DGNotificationManager instance] observer:self shouldProcessNotification:context])
    {
        return;
    }

    if ([[context name] isEqualToString:UI_MENU_DOUBLE_TAPPED])
    {
        assert([[context object] isKindOfClass:[UIButton class]]);

        if (![self buttonIgnoresDoubleTap:[context object]])
        {
            [[DGNotificationManager instance] notify:UI_DISMISS_SUPPORT_UI_REQUESTED];
        }
    }
    if ([[context name] isEqualToString:UIDeviceOrientationDidChangeNotification])
    {
        // The device notification arrives before the interface rotates, so rotate for the orientation the
        // interface is about to have rather than the one it has now.
        [self rotateMenuIconsToInterfaceOrientation:[self expectedInterfaceOrientation] animated:true];
    }
}

#pragma mark - Icon rotation

// The orientation the interface is currently laid out in.
- (UIInterfaceOrientation) currentInterfaceOrientation
{
    UIInterfaceOrientation orientation = self.view.window.windowScene.interfaceOrientation;
    return ((orientation == UIInterfaceOrientationUnknown) ? UIInterfaceOrientationPortrait : orientation);
}

// The orientation the interface will have once it has followed the device. The interface only follows if
// the host supports that orientation; otherwise (e.g. a portrait-locked host) it stays where it is.
- (UIInterfaceOrientation) expectedInterfaceOrientation
{
    UIInterfaceOrientation following = [self currentInterfaceOrientation];
    switch ([UIDevice currentDevice].orientation)
    {
        case UIDeviceOrientationPortrait:
            following = UIInterfaceOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            following = UIInterfaceOrientationPortraitUpsideDown;
            break;
        // The device and interface landscape orientations are mirrored.
        case UIDeviceOrientationLandscapeLeft:
            following = UIInterfaceOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            following = UIInterfaceOrientationLandscapeLeft;
            break;
        default:
            return [self currentInterfaceOrientation];
    }

    // A hosting controller (e.g. SwiftUI's) reports every orientation regardless of the app's Info.plist,
    // which UIKit applies separately, so both restrictions are applied here.
    UIInterfaceOrientationMask supported = (self.view.window.rootViewController.supportedInterfaceOrientations & [self infoPlistSupportedInterfaceOrientations]);
    return (((1 << following) & supported) ? following : [self currentInterfaceOrientation]);
}

// The orientations the app declares in its Info.plist. All orientations if none are declared.
- (UIInterfaceOrientationMask) infoPlistSupportedInterfaceOrientations
{
    // Returns the device-specific variant (e.g. ~iphone) in preference to the general key.
    NSArray *declared = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
    if (![declared isKindOfClass:[NSArray class]] || (declared.count == 0))
    {
        return UIInterfaceOrientationMaskAll;
    }

    NSDictionary *masks = @{ @"UIInterfaceOrientationPortrait" : @(UIInterfaceOrientationMaskPortrait),
                             @"UIInterfaceOrientationPortraitUpsideDown" : @(UIInterfaceOrientationMaskPortraitUpsideDown),
                             @"UIInterfaceOrientationLandscapeLeft" : @(UIInterfaceOrientationMaskLandscapeLeft),
                             @"UIInterfaceOrientationLandscapeRight" : @(UIInterfaceOrientationMaskLandscapeRight) };
    UIInterfaceOrientationMask supported = 0;
    for (NSString *name in declared)
    {
        supported |= [[masks objectForKey:name] unsignedIntegerValue];
    }
    return supported;
}

- (void) rotateMenuIconsToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation animated:(bool)animated
{
    [self.mainMenuViewController rotateIconsToDeviceOrientationWithAnimation:animated interfaceOrientation:interfaceOrientation];

    // NOTE:  The "is visible" calculations are very explicit and accurate, but may be a little
    // overkill. I don't think they are currently a processing burden, but for large data sets, it
    // may be worthwhile to streamline those checks.
    if ([self isViewTopmostInActiveMenuContainer:self.favoritesMenuViewController.view])
    {
        [self.favoritesMenuViewController rotateIconsToDeviceOrientationWithAnimation:animated interfaceOrientation:interfaceOrientation];
    }

    for (DGScrollableMenuViewController *submenuViewController in self.submenuViewControllers)
    {
        [submenuViewController rotateIconsToDeviceOrientationWithAnimation:(animated && [self isViewTopmostInActiveMenuContainer:submenuViewController.view]) interfaceOrientation:interfaceOrientation];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // The shelf may appear while the device is held differently from the interface.
    [self rotateMenuIconsToInterfaceOrientation:[self currentInterfaceOrientation] animated:false];
}

// Settles the icons once an interface rotation finishes, in case the interface ended up somewhere other
// than where it was expected to.
- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    __weak typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
    {
        [weakSelf rotateMenuIconsToInterfaceOrientation:[weakSelf currentInterfaceOrientation] animated:false];
    }];
}

#pragma mark - Support view mode

- (void) transitionToSupportViewMode:(DGSupportViewMode)newMode
{
    self.supportViewMode = newMode;

    [[self.mainMenuViewContainer subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [[self.activeMenuViewContainer subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    if (self.supportViewMode == DGSupportViewModeFavorites)
    {
        if (self.favoritesMenuViewController)
        {
            self.favoritesMenuViewController.view.frame = [self favoritesMenuFrame];
            [self.activeMenuViewContainer addSubview:self.favoritesMenuViewController.view];
        }
    }
    else
    {
        if (![self.mainMenuViewContainer.subviews containsObject:self.mainMenuViewController.view])
        {
            [self.mainMenuViewContainer addSubview:self.mainMenuViewController.view];
        }
        if (self.activeMenuViewController)
        {
            self.activeMenuViewController.view.frame = self.activeMenuViewContainer.bounds;
            [self.activeMenuViewContainer addSubview:self.activeMenuViewController.view];
        }
    }

    [self applyStylingStatesToMenus];
}

#pragma mark - UI state

- (NSUInteger) menuButtonIndex
{
    NSUInteger index = [self.mainMenuButtons indexOfObject:self.activeMainMenuButton];
    if (index == NSNotFound)
    {
        index = 0;
    }

    return index;
}

- (NSDictionary *) menuStates
{
    NSMutableDictionary *menuStates = [[NSMutableDictionary alloc] initWithCapacity:(self.submenuViewControllers.count + 2)];

    if (self.mainMenuViewController)
    {
        [menuStates setObject:[[DGMenuUIState alloc] initWithStateManager:self.mainMenuViewController] forKey:self.mainMenuViewController.name];
    }
    if (self.favoritesMenuViewController)
    {
        [menuStates setObject:[[DGMenuUIState alloc] initWithStateManager:self.favoritesMenuViewController] forKey:self.favoritesMenuViewController.name];
    }

    for (DGScrollableMenuViewController *menu in self.submenuViewControllers)
    {
        if ([menu conformsToProtocol:@protocol(DGMenuUIStateManagerProtocol)])
        {
            [menuStates setObject:[[DGMenuUIState alloc] initWithStateManager:menu] forKey:menu.name];
        }
    }

    return menuStates;
}

#pragma mark - Menu display and styling

- (void) mainMenuButtonClicked:(id)sender
{
    DGShelfMenuDefinition *menu = [self menuForMainMenuButton:sender];
    if (menu)
    {
        [self displayMenu:menu];
    }
}

- (void) displayMenuNamed:(NSString *)name
{
    for (DGShelfMenuDefinition *menu in self.menus)
    {
        if ([menu.name isEqualToString:name])
        {
            [self displayMenu:menu];
            return;
        }
    }
}

- (void) displayMenu:(DGShelfMenuDefinition *)menu
{
    DGScrollableMenuViewController *menuViewController = [self.submenuViewControllersByName objectForKey:menu.name];
    if (!menuViewController)
    {
        return;
    }

    [[self.activeMenuViewContainer subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    self.activeMainMenuButton = menu.menuButton;
    menuViewController.view.frame = self.activeMenuViewContainer.bounds;
    [self.activeMenuViewContainer addSubview:menuViewController.view];
    self.activeMenuViewController = menuViewController;
    [self applyStylingStatesToMenus];

    // The host persists the shelf's state in response.
    [[DGNotificationManager instance] notify:UI_SAVE_UI_STATE];
}

- (void) applyActiveState:(bool)active toButton:(UIButton *)button
{
    for (DGShelfMenuDefinition *menu in self.menus)
    {
        if ([menu.buttons containsObject:button])
        {
            [[self.submenuViewControllersByName objectForKey:menu.name] applyActiveStateToMenuButton:button isActive:active];
        }
    }
    if ([self.favoritesMenu.buttons containsObject:button])
    {
        [self.favoritesMenuViewController applyActiveStateToMenuButton:button isActive:active];
    }
}

- (void) applyStylingStatesToMenus
{
    for (UIButton *mainButton in self.mainMenuButtons)
    {
        [mainButton setBackgroundImage:nil forState:UIControlStateNormal];
        if ([self.activeMainMenuButton isEqual:mainButton])
        {
            mainButton.backgroundColor = self.displayConfiguration.activeSubBackgroundColor;
            [mainButton setBackgroundImage:[DGShelfGraphicsUtils borderShadowImageForRect:mainButton.bounds sides:(DGShelfRectSidesLeft | DGShelfRectSidesTop | DGShelfRectSidesRight) color:self.displayConfiguration.activeSubBorderColor] forState:UIControlStateNormal];
            CGRect exclusionRect = [mainButton convertRect:mainButton.bounds toView:self.activeMenuViewController.view];
            [self.activeMenuViewController updateBorderToExcludeRegion:exclusionRect];
        }
        else
        {
            mainButton.backgroundColor = self.displayConfiguration.mainBackgroundColor;
        }
    }
}

@end
