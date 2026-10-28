//
//  DGPresentationCardViewController.m
//  DGCoreUI
//
//  Created by Mark Johnson on 11/21/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <CoreImage/CoreImage.h>

#import <DGCoreUI/DGComponentTypeDefinitions.h>

#import "DGPresentationCardViewController.h"

#import "DGPresentationCardCustomViewControllerProtocol.h"

#import "DGNotificationManager.h"

#define UI_EMPTY_CARD_ICON_CORNER_RADIUS 5.0f

#define UI_PROPERTY_OBSERVER_KEY_TEXT_VIEW_CONTENT_SIZE @"contentSize"

@interface DGPresentationCardViewController()

@property (strong, nonatomic) NSString *cardText;
@property (strong, nonatomic) UIImage *cardImage;
@property (nonatomic) CGRect highlightRegion;
@property (strong, nonatomic) NSString *action;
@property (strong, nonatomic) UIView *cardView;
@property (strong, nonatomic) UIViewController *cardViewController;

@property (strong, nonatomic) UITextView *cardTextView;
@property (strong, nonatomic) UIImageView *cardImageView;

@end


@implementation DGPresentationCardViewController

@synthesize cardText = _cardText;
@synthesize cardImage = _cardImage;
@synthesize highlightRegion = _highlightRegion;
@synthesize action = _action;
@synthesize cardView = _cardView;
@synthesize cardViewController = _cardViewController;

@synthesize cardTextView = _cardTextView;
@synthesize cardImageView = _cardImageView;

+ (id) emptyCard
{
    return [[DGPresentationCardViewController alloc] initWithText:nil textColor:nil];
}

- (id) initWithText:(NSString *)cardText textColor:(UIColor *)textColor
{
    self = [super init];
    if (self)
    {
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UI_DEFAULT_PRESENTATION_CARD_WIDTH, UI_DEFAULT_PRESENTATION_CARD_HEIGHT)];
        self.view.userInteractionEnabled = true;
        if (!cardText)
        {
            cardText = @"";
        }
        self.cardText = cardText;
        
        if ((self.cardText) && (self.cardText.length > 0))
        {
            self.cardTextView = [[UITextView alloc] initWithFrame:self.view.frame];
            self.cardTextView.text = self.cardText;
            self.cardTextView.editable = false;
            self.cardTextView.scrollEnabled = true;
            if ([self.cardTextView respondsToSelector:@selector(setTintColor:)])
            {
                self.cardTextView.tintColor = textColor;
            }
            self.cardTextView.backgroundColor = [UIColor whiteColor];
            self.cardTextView.textAlignment = NSTextAlignmentCenter;
            self.cardTextView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
            self.cardTextView.textColor = textColor;
            self.cardTextView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            [self.view addSubview:self.cardTextView];
            [self.cardTextView setContentOffset:(CGPointZero) animated:false];
            [self.cardTextView addObserver:self forKeyPath:UI_PROPERTY_OBSERVER_KEY_TEXT_VIEW_CONTENT_SIZE options:(NSKeyValueObservingOptionNew) context:NULL];
        }
    }
    return self;
}

- (id) initWithText:(NSString *)cardText textColor:(UIColor *)textColor image:(UIImage *)cardImage
{
    self = [self initWithText:cardText textColor:textColor];
    if (self)
    {
        self.cardImage = cardImage;
        
        if (self.cardImage)
        {
            self.cardImageView = [[UIImageView alloc] initWithImage:self.cardImage];
            self.cardImageView.contentMode = UIViewContentModeScaleAspectFit;
            self.cardImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            [self.view addSubview:self.cardImageView];
        }
    }
    return self;
}

- (id) initWithText:(NSString *)cardText textColor:(UIColor *)textColor image:(UIImage *)cardImage highlightRegion:(CGRect)region
{
    self = [self initWithText:cardText textColor:textColor image:cardImage];
    if (self)
    {
        self.highlightRegion = region;
    }
    return self;
}

- (id) initWithText:(NSString *)cardText textColor:(UIColor *)textColor image:(UIImage *)cardImage highlightRegion:(CGRect)region action:(NSString *)actionNotification
{
    self = [self initWithText:cardText textColor:textColor image:cardImage highlightRegion:region];
    if (self)
    {
        if ((actionNotification) && (actionNotification.length > 0))
        {
            self.action = actionNotification;
        }
    }
    return self;
}

- (id) initWithCustomView:(UIView *)view highlightRegion:(CGRect)region action:(NSString *)actionNotification
{
    self = [self initWithText:nil textColor:nil image:nil highlightRegion:region action:actionNotification];
    if (self)
    {
        self.cardView = view;
        
        if (self.cardView)
        {
            self.cardView.frame = self.view.frame;
            self.cardView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            [self.view addSubview:self.cardView];
        }
    }
    return self;
}

- (id) initWithCustomViewController:(UIViewController *)viewController highlightRegion:(CGRect)region action:(NSString *)actionNotification
{
    self = [self initWithCustomView:viewController.view highlightRegion:region action:actionNotification];
    if (self)
    {
        self.cardViewController = viewController;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self layoutCardContent];
}

// Laying out here (rather than only in viewDidAppear) keeps the content from visibly resizing after the
// card is first displayed.
- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self layoutCardContent];
}

- (void) layoutCardContent
{
    if (![self isCardEmpty])
    {
        if (self.cardView)
        {
            self.cardView.frame = CGRectMake(self.view.bounds.origin.x + 20.0f, self.view.frame.origin.y + 20.0f, self.view.bounds.size.width - 40.0f, self.view.bounds.size.height - 40.0f);
        }
        else
        {
            if (self.cardImage)
            {
                CGFloat height = self.view.bounds.size.height - 40.0f;
                if ((self.cardText) && (self.cardText.length > 0))
                {
                    if (self.cardImage.size.height > ((self.view.bounds.size.height - 40.0f) / 2.0f))
                    {
                        height = (self.view.bounds.size.height / 2.0f) - 5.0f;
                    }
                    else
                    {
                        height = self.cardImage.size.height;
                    }
                }
                self.cardImageView.frame = CGRectMake(self.view.bounds.origin.x + 20.0f, self.view.frame.origin.y + 20.0f, self.view.bounds.size.width - 40.0f, height);
            }
            if ((self.cardText) && (self.cardText.length > 0))
            {
                CGFloat height = self.view.bounds.size.height - 40.0f;
                CGFloat y = self.view.frame.origin.y + 20.0f;
                if (self.cardImage)
                {
                    height = self.view.bounds.size.height - self.cardImageView.bounds.size.height - 50.0f;
                    y = (self.cardImageView.frame.origin.y + self.cardImageView.bounds.size.height + 10.0f);
                }
                self.cardTextView.frame = CGRectMake(self.view.bounds.origin.x + 20.0f, y, self.view.bounds.size.width - 40.0f, height);
            }
        }
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self.cardTextView removeObserver:self forKeyPath:UI_PROPERTY_OBSERVER_KEY_TEXT_VIEW_CONTENT_SIZE];
    
    [super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
//    if (![pnbSystemUtils isFullScreenModalPresented])
//    {
        self.cardText = nil;
        self.cardImage = nil;
        self.action = nil;
        [self removeFromParentViewController];
        [self.cardView removeFromSuperview];
        self.cardView = nil;
        self.cardViewController = nil;
//    }
}

- (bool) isCardEmpty
{
    return (((!self.cardText) || ((self.cardText) && (self.cardText.length == 0))) && (!self.cardImage) && (!self.cardView));
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:UI_PROPERTY_OBSERVER_KEY_TEXT_VIEW_CONTENT_SIZE])
    {
        UITextView *textView = object;
        CGFloat heightAdjustment = ([textView bounds].size.height - [textView contentSize].height * [textView zoomScale])/2.0;
        heightAdjustment = ((heightAdjustment < 0.0) ? 0.0 : heightAdjustment);
        textView.contentOffset = CGPointMake(0.0, -heightAdjustment);
    }
}

- (void) cardBecameActive
{
    if ((self.action) && (self.action.length > 0))
    {
        [[DGNotificationManager instance] notify:self.action];
    }
}

- (void) handleUserDismissal:(DGCardPresentationDismissAction)action
{
    if ((self.cardViewController) && ([self.cardViewController conformsToProtocol:@protocol(DGPresentationCardCustomViewControllerProtocol)]) && ([self.cardViewController respondsToSelector:@selector(handleUserDismissal:)]))
    {
        [(id<DGPresentationCardCustomViewControllerProtocol>)self.cardViewController handleUserDismissal:action];
    }
}

- (void) handleDismissalAfterPresentationCloses:(DGCardPresentationDismissAction)action
{
    if ((self.cardViewController) && ([self.cardViewController conformsToProtocol:@protocol(DGPresentationCardCustomViewControllerProtocol)]) && ([self.cardViewController respondsToSelector:@selector(handleDismissalAfterPresentationCloses:)]))
    {
        [(id<DGPresentationCardCustomViewControllerProtocol>)self.cardViewController handleDismissalAfterPresentationCloses:action];
    }
}

@end
