//
//  DGScrollableMenuViewController.m
//  DGCoreUI
//
//  Created by Mark Johnson on 1/17/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <tgmath.h>

#import "DGScrollableMenuViewController.h"

#import "DGUIStateProtocol.h"
#import "DGToolShelfUIStateManagerProtocol.h"
#import "DGMenuUIStateManagerProtocol.h"
#import "DGShelfGraphicsUtils.h"

#import <DGCoreUI/DGNotificationManager.h>

#define SHELF_ANIMATION_ICON_ROTATION_DURATION 0.3f

#define SHELF_LEFT_SHUTTLE_INDICATOR @"<"
#define SHELF_RIGHT_SHUTTLE_INDICATOR @">"

#define SHELF_ANIMATION_BOUNCE_WIDTH_RATIO 0.1
#define SHELF_SHUTTLE_BUTTON_CONTROL_WIDTH 15.0
#define SHELF_BUTTON_CONTROL_PADDING_MAIN 1.0
#define SHELF_BUTTON_CONTROL_PADDING_SUB 3.0
#define SHELF_BUTTON_CONTROL_DEFAULT_WIDTH 20.0
#define SHELF_BUTTON_CONTROL_DEFAULT_HEIGHT SHELF_BUTTON_CONTROL_DEFAULT_WIDTH

@interface DGScrollableMenuViewControllerSlidingContentView : UIScrollView

@end

@implementation DGScrollableMenuViewControllerSlidingContentView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    if ([view isKindOfClass:[UIButton class]])
    {
        return true;
    }
    return [super touchesShouldCancelInContentView:view];
}

@end

@interface DGScrollableMenuViewController ()

@property DGMenuType type;

@property (strong, readwrite, nonatomic) NSString *name;

@property DGToolShelfDisplayConfiguration displayConfiguration;

// Size of the view the buttons were last positioned for; used to reposition when the view is resized.
@property CGSize positionedSize;

@property (strong) UIImageView *shelfShadow;

@property CGFloat buttonWidth;
@property CGFloat buttonHeight;
@property CGFloat buttonPadding;

@property NSInteger numberOfVisibleIcons;

@property (strong) DGScrollableMenuViewControllerSlidingContentView *contentScrollView;
@property (strong) NSArray *buttons;

@property (strong) UIButton *leftShuttleButton;
@property (strong) UIButton *rightShuttleButton;

@property CGPoint scrollContentOffset;

- (void) positionButtons;
- (void) positionButtonsWithButtons:(NSArray *)buttons;

- (IBAction) shuttleLeftClicked:(id)sender;
- (IBAction) shuttleRightClicked:(id)sender;

@end


@implementation DGScrollableMenuViewController

@synthesize type = _type;

@synthesize displayConfiguration = _displayConfiguration;
@synthesize positionedSize = _positionedSize;

@synthesize shelfShadow = _shelfShadow;

@synthesize buttonWidth = _buttonWidth;
@synthesize buttonHeight = _buttonHeight;
@synthesize buttonPadding = _buttonPadding;

@synthesize numberOfVisibleIcons = _numberOfVisibleIcons;

@synthesize contentScrollView = _contentScrollView;
@synthesize buttons = _buttons;

@synthesize leftShuttleButton = _leftShuttleButton;
@synthesize rightShuttleButton = _rightShuttleButton;

@synthesize scrollContentOffset = _scrollContentOffset;

- (id) initWithButtons:(NSArray *)buttons withNumberVisible:(NSInteger)numberVisible asType:(DGMenuType)type withName:(NSString *)name withState:(id<DGUIStateProtocol>)state displayConfiguration:(DGToolShelfDisplayConfiguration)configuration
{
    self = [self init];
    if (self)
    {
        self.name = name;
        self.type = type;
        self.displayConfiguration = configuration;
        
        self.shelfShadow = [[UIImageView alloc] initWithImage:nil];
        self.shelfShadow.frame = self.view.frame;
        self.shelfShadow.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:self.shelfShadow];
        
        self.numberOfVisibleIcons = numberVisible;
        
        self.buttonHeight = SHELF_BUTTON_CONTROL_DEFAULT_HEIGHT;
        self.buttonWidth = SHELF_BUTTON_CONTROL_DEFAULT_WIDTH;
        
        if (self.type == DGMenuTypeSub)
        {
            self.buttonPadding = SHELF_BUTTON_CONTROL_PADDING_SUB;
            self.view.backgroundColor = self.displayConfiguration.activeSubBackgroundColor;
        }
        else
        {
            self.buttonPadding = SHELF_BUTTON_CONTROL_PADDING_MAIN;
            self.view.backgroundColor = self.displayConfiguration.mainBackgroundColor;
        }
        
        self.buttons = buttons;

        for (UIButton *button in self.buttons)
        {
            button.contentMode = UIViewContentModeCenter;

            // The icons are counter-rotated through the image view's transform, and UIKit swaps a rotated
            // view's width and height when the button lays it out. Aspect fit keeps a non-square icon from
            // being stretched to fill the swapped bounds.
            button.imageView.contentMode = UIViewContentModeScaleAspectFit;

            if (self.type == DGMenuTypeSub)
            {
                button.layer.cornerRadius = 5.0;
                button.layer.borderWidth = 1.0;
                button.layer.borderColor = self.displayConfiguration.contentButtonBorderColor.CGColor;
                button.backgroundColor = self.displayConfiguration.contentBackgroundColor;
                
                // A gesture recognizer can only be associated with one view; have to instantiate
                // a new one for each button.
                UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
                doubleTapGesture.numberOfTapsRequired = 2;

                [button addGestureRecognizer:doubleTapGesture];
            }
        }
        
        if ([state conformsToProtocol:@protocol(DGToolShelfUIStateManagerProtocol)])
        {
            state = [((id<DGToolShelfUIStateManagerProtocol>)state).menuStates objectForKey:self.name];
        }

        if ([state conformsToProtocol:@protocol(DGMenuUIStateManagerProtocol)])
        {
            self.scrollContentOffset = ((id<DGMenuUIStateManagerProtocol>)state).scrollOffset;
        }
        else
        {
            self.scrollContentOffset = CGPointMake(0.0, 0.0);
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self positionButtons];
}

// The shelf adds this view to a container without relying on appearance callbacks, so reposition the
// buttons whenever the view's size changes.
- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    if ((!CGRectIsEmpty(self.view.bounds)) && (!CGSizeEqualToSize(self.view.bounds.size, self.positionedSize)))
    {
        [self positionButtons];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateRecognized)
    {
        [[DGNotificationManager instance] notify:UI_MENU_DOUBLE_TAPPED withData:sender.view];
    }
}

- (void) rotateIconsToDeviceOrientationWithAnimation:(bool)animate interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    NSTimeInterval duration = (animate?SHELF_ANIMATION_ICON_ROTATION_DURATION:0.0f);

    [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseInOut
     animations:^
     {
        for (UIButton *button in self.buttons)
        {
            [DGShelfGraphicsUtils rotateToDeviceOrientationContentsOfView:button.imageView interfaceOrientation:interfaceOrientation];
        }
     }
     completion:^(BOOL finished)
     {
     }];
}

- (void) positionButtons
{
    [self positionButtonsWithButtons:self.buttons];
}

- (void) positionButtonsWithButtons:(NSArray *)buttons
{
    CGFloat shuttleOffset = 0.0;
    
    self.positionedSize = self.view.bounds.size;

    if (self.type == DGMenuTypeSub)
    {
        self.shelfShadow.frame = self.view.bounds;
        self.shelfShadow.image = [DGShelfGraphicsUtils borderShadowImageForRect:self.shelfShadow.bounds sides:(DGShelfRectSidesTop | DGShelfRectSidesLeft | DGShelfRectSidesRight | DGShelfRectSidesBottom) color:self.displayConfiguration.activeSubBorderColor];
    }
    
    if (buttons.count > self.numberOfVisibleIcons)
    {
        if (!self.leftShuttleButton)
        {
            UIButton *leftShuttleButton = [UIButton buttonWithType:UIButtonTypeCustom];
            leftShuttleButton.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, SHELF_SHUTTLE_BUTTON_CONTROL_WIDTH, self.view.bounds.size.height);
            [leftShuttleButton setTitle:SHELF_LEFT_SHUTTLE_INDICATOR forState:UIControlStateNormal];
            [leftShuttleButton setTitleColor:self.displayConfiguration.textColor forState:UIControlStateNormal];
            // To use shuttle icons, import an icon file into the project and enable this.
            //[leftShuttleButton setBackgroundImage:[UIImage imageNamed:@"shuttleleft.png"] forState:UIControlStateNormal];
            leftShuttleButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [leftShuttleButton addTarget:self action:@selector(shuttleLeftClicked:) forControlEvents:UIControlEventTouchUpInside];
            self.leftShuttleButton = leftShuttleButton;
            [self.view addSubview:self.leftShuttleButton];
        }
        
        if (!self.rightShuttleButton)
        {
            UIButton *rightShuttleButton = [UIButton buttonWithType:UIButtonTypeCustom];
            rightShuttleButton.frame = CGRectMake(self.view.bounds.size.width-SHELF_SHUTTLE_BUTTON_CONTROL_WIDTH, self.view.bounds.origin.y, SHELF_SHUTTLE_BUTTON_CONTROL_WIDTH, self.view.bounds.size.height);
            [rightShuttleButton setTitle:SHELF_RIGHT_SHUTTLE_INDICATOR forState:UIControlStateNormal];
            [rightShuttleButton setTitleColor:self.displayConfiguration.textColor forState:UIControlStateNormal];
            // To use shuttle icons, import an icon file into the project and enable this.
            //[rightShuttleButton setBackgroundImage:[UIImage imageNamed:@"shuttleright.png"] forState:UIControlStateNormal];
            rightShuttleButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [rightShuttleButton addTarget:self action:@selector(shuttleRightClicked:) forControlEvents:UIControlEventTouchUpInside];
            self.rightShuttleButton = rightShuttleButton;
            [self.view addSubview:self.rightShuttleButton];
        }
        
        shuttleOffset = self.leftShuttleButton.bounds.size.width;
    }
    
    CGRect contentVisibleRect = CGRectMake((self.view.bounds.origin.x + shuttleOffset), self.view.bounds.origin.y, (self.view.bounds.size.width - (shuttleOffset * 2.0)), self.view.bounds.size.height);
    // Reuse the scroll view (and so the buttons' superview) on repositioning. Rebuilding it would re-parent
    // every button, which cancels in-flight animations such as the icon rotation.
    if (!self.contentScrollView)
    {
        self.contentScrollView = [[DGScrollableMenuViewControllerSlidingContentView alloc] initWithFrame:contentVisibleRect];
        self.contentScrollView.delegate = self;
    }
    else
    {
        self.contentScrollView.frame = contentVisibleRect;
    }

    CGFloat buttonWidth = (self.contentScrollView.bounds.size.width - ((self.numberOfVisibleIcons + 1) * self.buttonPadding)) / self.numberOfVisibleIcons;
    buttonWidth = floor(buttonWidth);
    if (buttonWidth < 0.0)
    {
        buttonWidth = 0.0;
    }
    
    NSInteger numberMissingButtons = self.numberOfVisibleIcons - buttons.count;
    CGFloat offset = 0.0;
    CGFloat spacing = 0.0;
    if (numberMissingButtons > 0)
    {
        if (self.type == DGMenuTypeMain)
        {
            // Center with no spacing.
            offset = (numberMissingButtons*(buttonWidth+self.buttonPadding))/2.0;
        }
        else
        {
            // Space evenly.
            spacing = ((numberMissingButtons*(buttonWidth+self.buttonPadding)) / buttons.count);
            offset = spacing / 2.0;
        }
        offset = floor(offset);
        spacing = floor(spacing);
    }
    
    CGFloat buttonHeightOffset = 0.0;
    CGFloat buttonHeightPaddingMultiplier = 0.0; // NOTE:  This is a little convoluted.  Could accomplish with nothing more than the height offset set to zero.  The real answer would be to make a custom button class where the padding and height are baked in.
    if (self.type == DGMenuTypeSub)
    {
        buttonHeightOffset = self.buttonPadding;
        buttonHeightPaddingMultiplier = 1.0;
    }
    CGFloat buttonHeight = self.contentScrollView.bounds.size.height - (self.buttonPadding * 2.0 * buttonHeightPaddingMultiplier);
    buttonHeight = floor(buttonHeight);
    CGFloat x = self.contentScrollView.bounds.origin.x + self.buttonPadding + offset;
    CGFloat y = self.contentScrollView.bounds.origin.y + buttonHeightOffset;
    for (UIButton *button in buttons)
    {
        button.frame = CGRectMake(x, y, buttonWidth, buttonHeight);
        button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        x += buttonWidth + self.buttonPadding + spacing;
        
        // Production Crash Report:  Receiving crash on adding of buttons in subview.  All crashes
        // trace to the hiding and showing of buttons within the scrollable menu.  Ensure the scroll
        // view is properly sized prior to adding the button.
        CGSize scrollSize = CGSizeMake((((buttonWidth+self.buttonPadding) * buttons.count) + self.buttonPadding), buttonHeight);
        self.contentScrollView.contentSize = scrollSize;
        
        // Production Crash Report:  Receiving crash on adding of buttons in subview.  Placed
        // guard condition to verify that the view is ready to have views added.
        // Production Crash Report:  Receiving crash on adding of buttons in subview stating
        // target object doesn't respond to selector.  Augmenting previous fix to ensure both
        // objects involved in the add operation are properly configured.
        if ( ((self.isViewLoaded) && (self.contentScrollView)) && ((button) && ([button isKindOfClass:[UIButton class]])) )
        {
            // Production Crash Report:  Receiving crash on adding of buttons in subview.  Placed
            // try..catch around the add to capture what's actually happening if we happen to
            // still hit the condition.
            @try
            {
                if (![self.contentScrollView.subviews containsObject:button])
                {
                    [self.contentScrollView addSubview:button];
                }
            }
            @catch (NSException *exception)
            {
            }
            @finally
            {
            }
        }
    }
    
    self.buttonWidth = buttonWidth;
    self.buttonHeight = buttonHeight;
    
    if (self.scrollContentOffset.x > 0.0)
    {
        if (((self.contentScrollView.contentSize.width - self.scrollContentOffset.x) - (self.buttonPadding)) <= self.contentScrollView.bounds.size.width)
        {
            self.scrollContentOffset = CGPointMake(self.contentScrollView.contentSize.width - self.contentScrollView.bounds.size.width, self.scrollContentOffset.y);
        }
    }
    [self.contentScrollView setContentOffset:self.scrollContentOffset animated:false];
    
    if (self.contentScrollView.superview != self.view)
    {
        [self.view addSubview:self.contentScrollView];
    }
    [self scrollViewDidScroll:self.contentScrollView];
}

- (void) applyActiveStateToMenuButton:(UIButton *)button isActive:(bool)active
{
    if ([[NSThread currentThread] isMainThread])
    {
        if ((active) && (button.enabled == true))
        {
            button.layer.borderColor = self.displayConfiguration.activeContentButtonBorderColor.CGColor;
            button.layer.borderWidth = 1.5;
        }
        else
        {
            button.layer.borderColor = self.displayConfiguration.contentButtonBorderColor.CGColor;
            button.layer.borderWidth = 1.0;
        }
    }
}

- (void) updateBorderToExcludeRegion:(CGRect)exclusionRegion
{
    self.shelfShadow.frame = self.view.bounds;
    self.shelfShadow.image = [DGShelfGraphicsUtils borderShadowImageForRect:self.shelfShadow.frame sides:(DGShelfRectSidesTop | DGShelfRectSidesLeft | DGShelfRectSidesRight | DGShelfRectSidesBottom) color:self.displayConfiguration.activeSubBorderColor excludingRegion:exclusionRegion eraseColor:self.displayConfiguration.activeSubBackgroundColor];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    // If shuttle icons are used, the icon will need to be hidden/shown appropriate here.
    if (ceil(scrollView.contentSize.width - scrollView.bounds.size.width) <= (scrollView.contentOffset.x + self.buttonPadding))
    {
        self.rightShuttleButton.enabled = false;
        [self.rightShuttleButton setTitle:@"" forState:UIControlStateNormal];
        [self.rightShuttleButton setTitleColor:self.displayConfiguration.textColor forState:UIControlStateNormal];
    }
    else
    {
        self.rightShuttleButton.enabled = true;
        [self.rightShuttleButton setTitle:SHELF_RIGHT_SHUTTLE_INDICATOR forState:UIControlStateNormal];
        [self.rightShuttleButton setTitleColor:self.displayConfiguration.textColor forState:UIControlStateNormal];
    }
    
    if (scrollView.contentOffset.x <= self.buttonPadding)
    {
        self.leftShuttleButton.enabled = false;
        [self.leftShuttleButton setTitle:@"" forState:UIControlStateNormal];
        [self.leftShuttleButton setTitleColor:self.displayConfiguration.textColor forState:UIControlStateNormal];
    }
    else
    {
        self.leftShuttleButton.enabled = true;
        [self.leftShuttleButton setTitle:SHELF_LEFT_SHUTTLE_INDICATOR forState:UIControlStateNormal];
        [self.leftShuttleButton setTitleColor:self.displayConfiguration.textColor forState:UIControlStateNormal];
    }
    self.scrollContentOffset = self.contentScrollView.contentOffset;
}

- (IBAction) shuttleRightClicked:(id)sender
{
    CGFloat contentOffset = self.contentScrollView.contentOffset.x;
    if (contentOffset < 0.0)
    {
        contentOffset = 0.0;
    }
    contentOffset = contentOffset + (self.buttonWidth + self.buttonPadding);
    if (((self.contentScrollView.contentSize.width - contentOffset) - (self.buttonPadding)) <= self.contentScrollView.bounds.size.width)
    {
        contentOffset = self.contentScrollView.contentSize.width - self.contentScrollView.bounds.size.width;
        [self bounce:DGShelfBounceAnimationDirectionRight contentOffset:contentOffset];
    }
    else
    {
        [self.contentScrollView setContentOffset:CGPointMake(contentOffset, self.contentScrollView.contentOffset.y) animated:true];
    }
    self.scrollContentOffset = self.contentScrollView.contentOffset;
}

- (IBAction) shuttleLeftClicked:(id)sender
{
    CGFloat contentOffset = self.contentScrollView.contentOffset.x;
    contentOffset = contentOffset - (self.buttonWidth + self.buttonPadding);
    if (contentOffset < self.buttonPadding)
    {
        contentOffset = 0.0;
        [self bounce:DGShelfBounceAnimationDirectionLeft contentOffset:contentOffset];
    }
    else
    {
        [self.contentScrollView setContentOffset:CGPointMake(contentOffset, self.contentScrollView.contentOffset.y) animated:true];
    }
    self.scrollContentOffset = self.contentScrollView.contentOffset;
}

- (void) bounce:(DGShelfBounceAnimationDirection)direction contentOffset:(CGFloat)contentOffset
{
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut
                     animations:^
     {
         int xLimit;
         if (direction == DGShelfBounceAnimationDirectionLeft)
         {
             xLimit = (contentOffset - (self.contentScrollView.bounds.size.width * SHELF_ANIMATION_BOUNCE_WIDTH_RATIO));
         }
         else
         {
             xLimit = (contentOffset + (self.contentScrollView.bounds.size.width * SHELF_ANIMATION_BOUNCE_WIDTH_RATIO));
         }
         [self.contentScrollView setContentOffset:CGPointMake(xLimit, 0.0) animated:false];
         self.scrollContentOffset = self.contentScrollView.contentOffset;
     }
                     completion:^(BOOL finished)
     {
         [self.contentScrollView setContentOffset:CGPointMake(contentOffset, 0.0) animated:true];
         self.scrollContentOffset = self.contentScrollView.contentOffset;
     }
     ];
}

- (CGPoint) scrollOffset
{
    return self.scrollContentOffset;
}

- (CGPoint) scrollContentOffset
{
    return _scrollContentOffset;
}

- (void) setScrollContentOffset:(CGPoint)scrollContentOffset
{
    _scrollContentOffset = scrollContentOffset;
    [[DGNotificationManager instance] notify:UI_SAVE_UI_STATE];
}

@end
