//
//  DGCardPresentationViewController.m
//  DGCoreUI
//
//  Created by Mark Johnson on 11/18/13.
//  Copyright (c) 2013 Digital Generalists, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <tgmath.h>

#import "DGCardPresentationViewController.h"

#import "DGPresentationCardCustomViewControllerProtocol.h"
#import "DGPresentationCardViewController.h"

#import "DGNotificationManager.h"

#define ANIMATION_MODE_TRANSITION_DURATION 0.5f
#define ANIMATION_MODE_TRANSITION_DELAY 0.0f

#define ANIMATION_HIGHLIGHT_TRANSITION_SEGMENT_DURATION 0.25f
#define ANIMATION_HIGHLIGHT_TRANSITION_GROW_SEGMENT_DELAY ANIMATION_HIGHLIGHT_TRANSITION_SEGMENT_DURATION
#define ANIMATION_HIGHLIGHT_TRANSITION_MASK_PROPERTY @"path"

#define ANIMATION_CARD_PRESENTATION_ENTRANCE_DURATION 0.35f
#define ANIMATION_CARD_PRESENTATION_OVERLAY_REMOVE_DURATION 0.2f
#define ANIMATION_CARD_PRESENTATION_EXIT_DURATION 0.5f
#define ANIMATION_CARD_PRESENTATION_EXIT_DELAY 0.0f

#define UI_DIALOG_CORNER_RADIUS 5.0f

#define UI_CARD_INDEX_INDICATOR_MAXIMUM_NUMBER_OF_CARDS 16

@interface DGCardPresentationViewController ()

@property IBOutlet UIView *dialogContainer;
@property IBOutlet UIScrollView *cardDeckContainer;
@property IBOutlet UIPageControl *cardIndexIndicator;
@property IBOutlet UIButton *dismissButton;
@property IBOutlet UIButton *acceptButton;
@property IBOutlet UIButton *declineButton;

@property NSArray *presentationCards;

@property id<DGPresentationCardProtocol> visibleCard;

@property CGRect drawnHighlightRegion;

@property NSUInteger indexOfFurthestViewedCard;

@property DGCardPresentationButtonTypes buttonTypes;

@property DGPresentationDisplayConfiguration displayConfiguration;

- (void) drawHighlightRegion:(CGRect)highlightRect roundingRadius:(NSInteger)radius;

- (IBAction) dismissButtonPressed:(id)sender;
- (IBAction) highlightDismissButtonOnPress:(id)sender;
- (IBAction) removeDismissButtonHighlight:(id)sender;
- (IBAction) acceptButtonPressed:(id)sender;
- (IBAction) highlightAcceptButtonOnPress:(id)sender;
- (IBAction) removeAcceptButtonHighlight:(id)sender;
- (IBAction) declineButtonPressed:(id)sender;
- (IBAction) highlightDeclineButtonOnPress:(id)sender;
- (IBAction) removeDeclineButtonHighlight:(id)sender;

@end

@implementation DGCardPresentationViewController

@synthesize host = _host;

@synthesize dialogContainer = _dialogContainer;
@synthesize cardDeckContainer = _cardDeckContainer;
@synthesize cardIndexIndicator = _cardIndexIndicator;
@synthesize dismissButton = _dismissButton;
@synthesize acceptButton = _acceptButton;
@synthesize declineButton = _declineButton;

@synthesize presentationCards = _presentationCards;

@synthesize visibleCard = _visibleCard;

@synthesize drawnHighlightRegion = _drawnHighlightRegion;

@synthesize indexOfFurthestViewedCard = _indexOfFurthestViewedCard;

@synthesize buttonTypes = _buttonTypes;

@synthesize displayConfiguration = _displayConfiguration;

- (id) initWithHost:(UIViewController *)host
{
    // The view hierarchy is built in code (see loadView), so no host storyboard is required.
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _host = host;
        self.presentationCards = [NSArray arrayWithObject:[DGPresentationCardViewController emptyCard]];
        self.visibleCard = nil;
        self.drawnHighlightRegion = CGRectZero;
        self.indexOfFurthestViewedCard = 0;
    }
    return self;
}

- (UIButton *) buttonWithTitle:(NSString *)title frame:(CGRect)frame action:(SEL)action highlightAction:(SEL)highlightAction removeHighlightAction:(SEL)removeHighlightAction
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = frame;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:highlightAction forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:removeHighlightAction forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel)];
    return button;
}

- (void) loadView
{
    const CGFloat cardWidth = UI_DEFAULT_PRESENTATION_CARD_WIDTH;
    const CGFloat cardHeight = UI_DEFAULT_PRESENTATION_CARD_HEIGHT;
    const CGFloat indicatorHeight = 20.0f;
    const CGFloat buttonHeight = 44.0f;

    UIView *rootView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = rootView;

    // viewDidLoad repositions the dialog; the margins keep it centered when the host resizes.
    self.dialogContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, cardWidth, cardHeight + indicatorHeight + buttonHeight)];
    self.dialogContainer.backgroundColor = [UIColor whiteColor];
    self.dialogContainer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [rootView addSubview:self.dialogContainer];

    self.cardDeckContainer = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, cardWidth, cardHeight)];
    self.cardDeckContainer.showsHorizontalScrollIndicator = false;
    [self.dialogContainer addSubview:self.cardDeckContainer];

    self.cardIndexIndicator = [[UIPageControl alloc] initWithFrame:CGRectMake(0.0f, cardHeight, cardWidth, indicatorHeight)];
    self.cardIndexIndicator.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.dialogContainer addSubview:self.cardIndexIndicator];

    CGFloat buttonY = cardHeight + indicatorHeight;

    self.dismissButton = [self buttonWithTitle:@"Got It" frame:CGRectMake(0.0f, buttonY, cardWidth, buttonHeight) action:@selector(dismissButtonPressed:) highlightAction:@selector(highlightDismissButtonOnPress:) removeHighlightAction:@selector(removeDismissButtonHighlight:)];
    [self.dialogContainer addSubview:self.dismissButton];

    // Accept/decline share the row; viewWillAppear removes whichever set the button types do not use.
    self.declineButton = [self buttonWithTitle:@"Decline" frame:CGRectMake(0.0f, buttonY, cardWidth / 2.0f, buttonHeight) action:@selector(declineButtonPressed:) highlightAction:@selector(highlightDeclineButtonOnPress:) removeHighlightAction:@selector(removeDeclineButtonHighlight:)];
    [self.dialogContainer addSubview:self.declineButton];

    self.acceptButton = [self buttonWithTitle:@"Accept" frame:CGRectMake(cardWidth / 2.0f, buttonY, cardWidth / 2.0f, buttonHeight) action:@selector(acceptButtonPressed:) highlightAction:@selector(highlightAcceptButtonOnPress:) removeHighlightAction:@selector(removeAcceptButtonHighlight:)];
    [self.dialogContainer addSubview:self.acceptButton];
}

- (id) initWithHost:(UIViewController *)host containerViewController:(UIViewController *)containerViewController
{
    self = [self initWithHost:host];
    if (self)
    {
        // Container view controller is not leveraged by this support view.
    }
    return self;
}

- (id) initWithHost:(UIViewController *)host presentationCards:(NSArray *)cards displayConfiguration:(DGPresentationDisplayConfiguration)configuration
{
    self = [self initWithHost:host];
    if (self)
    {
        if ((!cards) || (cards.count == 0))
        {
            cards = [NSArray arrayWithObject:[DGPresentationCardViewController emptyCard]];
        }
        
        NSMutableArray *validCards = [NSMutableArray arrayWithCapacity:cards.count];
        for (id card in cards)
        {
            if (([card conformsToProtocol:@protocol(DGPresentationCardProtocol) ]) && ([card isKindOfClass:[UIViewController class]]))
            {
                [validCards addObject:card];
            }
        }
        
        self.presentationCards = validCards;
        self.displayConfiguration = configuration;
    }
    return self;
}

- (id) initWithHost:(UIViewController *)host presentationCards:(NSArray *)cards displayConfiguration:(DGPresentationDisplayConfiguration)configuration buttonTypes:(DGCardPresentationButtonTypes)buttons
{
    self = [self initWithHost:host presentationCards:cards displayConfiguration:configuration];
    if (self)
    {
        self.buttonTypes = buttons;
    }
    return self;
}

- (id) initWithHost:(UIViewController *)host presentationCards:(NSArray *)cards backgroundColor:(UIColor *)backgroundColor pageIndicatorTintColor:(UIColor *)pageIndicatorTintColor currentPageIndicatorTintColor:(UIColor *)currentPageIndicatorTintColor textColor:(UIColor *)textColor highlightedTextColor:(UIColor *)highlightedTextColor topOffset:(CGFloat)topOffset statusBarHeight:(CGFloat)statusBarHeight buttonTypes:(DGCardPresentationButtonTypes)buttons
{
    DGPresentationDisplayConfiguration configuration;
    configuration.backgroundColor = backgroundColor;
    configuration.pageIndicatorTintColor = pageIndicatorTintColor;
    configuration.currentPageIndicatorTintColor = currentPageIndicatorTintColor;
    configuration.textColor = textColor;
    configuration.highlightedTextColor = highlightedTextColor;
    configuration.topOffset = topOffset;
    configuration.statusBarHeight = statusBarHeight;

    return [self initWithHost:host presentationCards:cards displayConfiguration:configuration buttonTypes:buttons];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *dismissButtonTitle = @"Got It";
    if (self.buttonTypes == DGCardPresentationButtonTypesIgnore)
    {
        dismissButtonTitle = @"No Thanks";
    }
    
    [self.dismissButton setTitle:dismissButtonTitle forState:UIControlStateNormal];
    
    self.cardDeckContainer.pagingEnabled = true;
    self.cardDeckContainer.delegate = self;
    
    self.dialogContainer.layer.cornerRadius = UI_DIALOG_CORNER_RADIUS;
    self.dialogContainer.layer.masksToBounds = true;
    
    self.cardIndexIndicator.hidesForSinglePage = true;
    self.cardIndexIndicator.userInteractionEnabled = false;
    self.cardIndexIndicator.numberOfPages = self.presentationCards.count;
    if (self.cardIndexIndicator.numberOfPages > UI_CARD_INDEX_INDICATOR_MAXIMUM_NUMBER_OF_CARDS)
    {
        [self.cardIndexIndicator removeFromSuperview];
    }
    self.cardIndexIndicator.currentPage = 0;
    self.visibleCard = [self.presentationCards objectAtIndex:0];
    
    self.view.backgroundColor = [self.displayConfiguration.backgroundColor  colorWithAlphaComponent:0.0f];
    
    self.cardIndexIndicator.pageIndicatorTintColor = self.displayConfiguration.pageIndicatorTintColor;
    self.cardIndexIndicator.currentPageIndicatorTintColor = self.displayConfiguration.currentPageIndicatorTintColor;
    
    self.dismissButton.titleLabel.textColor = self.displayConfiguration.textColor;
    
    CGFloat offset = 0.0f;
    CGRect cardFrame = CGRectMake(0.0, 0.0, 0.0, 0.0);
    for (UIViewController<DGPresentationCardProtocol> *card in self.presentationCards)
    {
        card.view.frame = CGRectMake((card.view.frame.origin.x + offset), card.view.frame.origin.y, card.view.frame.size.width, self.cardDeckContainer.frame.size.height);
        offset += card.view.frame.size.width;
        CGRect currentFrame = card.view.frame;
        if (currentFrame.size.height > cardFrame.size.height) {
            cardFrame = currentFrame;
        }
    }
    
    CGFloat containerControlsHeight = self.cardIndexIndicator.frame.size.height + self.dismissButton.frame.size.height + 10.0f;
    self.dialogContainer.frame = CGRectMake(self.view.bounds.origin.x + ((self.view.bounds.size.width/2.0)-(cardFrame.size.width/2.0)), self.view.bounds.origin.y + ((self.view.bounds.size.height/2.0)-((cardFrame.size.height/2.0) + containerControlsHeight)), cardFrame.size.width, cardFrame.size.height + containerControlsHeight);
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // The layout has settled by now, so slide the dialog in from the right at its final size.
    if (!CGAffineTransformIsIdentity(self.dialogContainer.transform))
    {
        [UIView animateWithDuration:ANIMATION_CARD_PRESENTATION_ENTRANCE_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^
        {
            self.dialogContainer.transform = CGAffineTransformIdentity;
        }
        completion:NULL];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    switch (self.buttonTypes)
    {
        case DGCardPresentationButtonTypesAcceptDecline:
            [self.dismissButton removeFromSuperview];
            self.dismissButton = nil;
            break;
        case DGCardPresentationButtonTypesDismiss:
        case DGCardPresentationButtonTypesIgnore:
        default:
            [self.acceptButton removeFromSuperview];
            self.acceptButton = nil;
            [self.declineButton removeFromSuperview];
            self.declineButton = nil;
            break;
    }
    
    NSUInteger scrollWidth = 0.0f;
    for (UIViewController<DGPresentationCardProtocol> *card in self.presentationCards)
    {
        scrollWidth += card.view.frame.size.width;
        [self.cardDeckContainer addSubview:card.view];
        // Lay the card out now so its content is at its final size when first rendered.
        [card.view layoutIfNeeded];
    }
    self.cardDeckContainer.contentSize = CGSizeMake(scrollWidth, self.cardDeckContainer.frame.size.height);

    // Start the dialog just off screen to the right; viewDidAppear slides it in.
    [UIView performWithoutAnimation:^
    {
        self.dialogContainer.transform = CGAffineTransformMakeTranslation([UIScreen mainScreen].bounds.size.width, 0.0f);
    }];

    [self beginReceivingNotifications];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    _host = nil;
    self.presentationCards = nil;
    
    [self stopReceivingNotifications];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (id) notificationContext
{
    return self;
}

- (void) beginReceivingNotifications
{
    [[DGNotificationManager instance] unregisterForAllNotifications:self];
    [[DGNotificationManager instance] registerObserver:self forNotifications:[NSArray arrayWithObjects:UI_DISMISS_CARD_PRESENTATION, nil]];
}

- (void) stopReceivingNotifications
{
    [[DGNotificationManager instance] unregisterForAllNotifications:self];
}

- (void) respondToMessage:(DGNotification *)context
{
    if (![[DGNotificationManager instance] observer:self shouldProcessNotification:context])
    {
        return;
    }
    
    if ([[context name] isEqualToString:UI_DISMISS_CARD_PRESENTATION])
    {
        DGCardPresentationDismissAction action = DGCardPresentationDismissActionCancel;
        if([[context object] isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *params = [context object];
            
            id actionParam = [params objectForKey:PRESENTATION_CARD_DISMISSAL_ACTION];
            assert([actionParam isKindOfClass:[NSNumber class]]);
            action = (DGCardPresentationDismissAction)[actionParam integerValue];
        }
        
        [self closePresentation:action];
    }
}

- (void) attachToContainerViewController:(UIViewController *)containerViewController
{
    // Can safely ignore.
}

- (void) transitionToSupportViewMode:(DGSupportViewMode)newMode
{
    [self transitionToSupportViewMode:newMode completion:NULL];
}

- (void) transitionToSupportViewMode:(DGSupportViewMode)newMode completion:(void(^)(void))completion
{
    // Load the view before animating. Otherwise the first access to self.view happens inside the animation
    // block below, and every frame viewDidLoad sets (dialog, cards, buttons) animates into place.
    [self loadViewIfNeeded];

    UIColor *backgroundColor = self.displayConfiguration.backgroundColor;
    if (newMode != DGSupportViewModeDisabledBackground)
    {
        backgroundColor = [backgroundColor colorWithAlphaComponent:0.0f];
    }
    
    [UIView animateWithDuration:ANIMATION_MODE_TRANSITION_DURATION delay:ANIMATION_MODE_TRANSITION_DELAY options:UIViewAnimationOptionCurveEaseOut animations:^
    {
        self.view.backgroundColor = backgroundColor;
    }
    completion:^(BOOL finished)
    {
        self.view.layer.zPosition = MAXFLOAT;
        
        if (completion != NULL)
        {
            completion();
        }
    }];
}

- (void) drawHighlightRegion:(CGRect)highlightRect roundingRadius:(NSInteger)radius
{
    CGFloat statusBarAdjustment = 0.0;
    statusBarAdjustment = self.displayConfiguration.statusBarHeight;
    CGFloat highlightRegionStatusBarAdjustment = statusBarAdjustment;
    if (statusBarAdjustment >= self.displayConfiguration.topOffset)
    {
        highlightRegionStatusBarAdjustment = statusBarAdjustment - self.displayConfiguration.topOffset;
        if (highlightRect.origin.y > ([UIScreen mainScreen].bounds.size.height / 2.0f))
        {
            highlightRegionStatusBarAdjustment = statusBarAdjustment;
        }
    }
    highlightRect = CGRectMake(highlightRect.origin.x, highlightRect.origin.y - highlightRegionStatusBarAdjustment,
        highlightRect.size.width, highlightRect.size.height);
    CGRect maskFrame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y - statusBarAdjustment, self.view.bounds.size.width,   [UIScreen mainScreen].bounds.size.height + (2.0f * statusBarAdjustment));
    
    if (!CGRectEqualToRect(self.drawnHighlightRegion, highlightRect))
    {
        CAShapeLayer* maskLayer = [CAShapeLayer layer];
        maskLayer.fillRule = kCAFillRuleEvenOdd;
        maskLayer.fillColor = [UIColor whiteColor].CGColor;
        UIBezierPath* path = [UIBezierPath bezierPathWithRect:maskFrame];
        [path setUsesEvenOddFillRule:true];
        
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:self.drawnHighlightRegion cornerRadius:radius];
        [circlePath setUsesEvenOddFillRule:true];
        [path appendPath:circlePath];
        
        maskLayer.path = path.CGPath;
        
        // NOTE:  To enable shifting from one highlight area to the next, disable the following lines.
        path = [UIBezierPath bezierPathWithRect:maskFrame];
        [path setUsesEvenOddFillRule:true];
        
        circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake((self.drawnHighlightRegion.origin.x + (self.drawnHighlightRegion.size.width / 2.0f)), (self.drawnHighlightRegion.origin.y + (self.drawnHighlightRegion.size.height / 2.0f)), 0.0f, 0.0f) cornerRadius:radius];
        [circlePath setUsesEvenOddFillRule:true];
        [path appendPath:circlePath];
        // NOTE:  End - To enable shifting from one highlight area to the next, disable the following lines.
        
        CABasicAnimation *shrinkAnimation = [CABasicAnimation animationWithKeyPath:ANIMATION_HIGHLIGHT_TRANSITION_MASK_PROPERTY];
        shrinkAnimation.fromValue = (id)maskLayer.path;
        shrinkAnimation.toValue = (__bridge id)path.CGPath;
        shrinkAnimation.duration = ANIMATION_HIGHLIGHT_TRANSITION_SEGMENT_DURATION;

        // NOTE:  To enable shifting from one highlight area to the next, disable the following lines.
        path = [UIBezierPath bezierPathWithRect:maskFrame];
        [path setUsesEvenOddFillRule:true];
        
        circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake((highlightRect.origin.x + (highlightRect.size.width / 2.0f)), (highlightRect.origin.y + (highlightRect.size.height / 2.0f)), 0.0f, 0.0f) cornerRadius:radius];
        [circlePath setUsesEvenOddFillRule:true];
        [path appendPath:circlePath];
        
        maskLayer.path = path.CGPath;
        // NOTE:  End - To enable shifting from one highlight area to the next, disable the following lines.
        
        path = [UIBezierPath bezierPathWithRect:maskFrame];
        [path setUsesEvenOddFillRule:true];

        circlePath = [UIBezierPath bezierPathWithRoundedRect:highlightRect cornerRadius:radius];
        [circlePath setUsesEvenOddFillRule:true];
        [path appendPath:circlePath];
        
        CABasicAnimation *growAnimation = [CABasicAnimation animationWithKeyPath:ANIMATION_HIGHLIGHT_TRANSITION_MASK_PROPERTY];
        growAnimation.beginTime = ANIMATION_HIGHLIGHT_TRANSITION_GROW_SEGMENT_DELAY;
        growAnimation.fromValue = (id)maskLayer.path;
        growAnimation.toValue = (__bridge id)path.CGPath;
        growAnimation.duration = ANIMATION_HIGHLIGHT_TRANSITION_SEGMENT_DURATION;
        
        maskLayer.path = path.CGPath;
        self.drawnHighlightRegion = highlightRect;
        
        CAAnimationGroup *animGroup = [CAAnimationGroup animation];
        animGroup.animations = [NSArray arrayWithObjects:shrinkAnimation, growAnimation, nil];
        animGroup.duration = ANIMATION_HIGHLIGHT_TRANSITION_SEGMENT_DURATION * animGroup.animations.count;
        [maskLayer addAnimation:animGroup forKey:nil];

        [self.view.layer setMask:maskLayer];
    }
}

- (IBAction) dismissButtonPressed:(id)sender
{
    [self closePresentation:DGCardPresentationDismissActionCancel];
}

- (IBAction) highlightDismissButtonOnPress:(id)sender
{
    self.dismissButton.titleLabel.textColor = self.displayConfiguration.highlightedTextColor;
}

- (IBAction) removeDismissButtonHighlight:(id)sender
{
    self.dismissButton.titleLabel.textColor = self.displayConfiguration.textColor;
}

- (IBAction) acceptButtonPressed:(id)sender
{
    [self closePresentation:DGCardPresentationDismissActionAccept];
}

- (IBAction) highlightAcceptButtonOnPress:(id)sender
{
    self.dismissButton.titleLabel.textColor = self.displayConfiguration.highlightedTextColor;
}

- (IBAction) removeAcceptButtonHighlight:(id)sender
{
    self.dismissButton.titleLabel.textColor = self.displayConfiguration.textColor;
}

- (IBAction) declineButtonPressed:(id)sender
{
    [self closePresentation:DGCardPresentationDismissActionDecline];
}

- (IBAction) highlightDeclineButtonOnPress:(id)sender
{
    self.dismissButton.titleLabel.textColor = self.displayConfiguration.highlightedTextColor;
}

- (IBAction) removeDeclineButtonHighlight:(id)sender
{
    self.dismissButton.titleLabel.textColor = self.displayConfiguration.textColor;
}

- (void) closePresentation:(DGCardPresentationDismissAction)action
{
    for (id card in self.presentationCards)
    {
        [card handleUserDismissal:action];
    }
    
    [UIView animateWithDuration:ANIMATION_CARD_PRESENTATION_OVERLAY_REMOVE_DURATION delay:ANIMATION_CARD_PRESENTATION_EXIT_DELAY options:UIViewAnimationOptionCurveEaseInOut animations:^
     {
         self.view.backgroundColor = [self.view.backgroundColor colorWithAlphaComponent:0.0f];
     }
                     completion:^(BOOL finished)
     {
         [UIView animateWithDuration:ANIMATION_CARD_PRESENTATION_EXIT_DURATION delay:ANIMATION_CARD_PRESENTATION_EXIT_DELAY options:UIViewAnimationOptionCurveEaseInOut animations:^
          {
              self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width,  [UIScreen mainScreen].bounds.size.height);
          }
                          completion:^(BOOL finished)
          {
              for (id card in self.presentationCards)
              {
                  [card handleDismissalAfterPresentationCloses:action];
              }
              
              [self.view removeFromSuperview];
              
              [[DGNotificationManager instance] notify:UI_CARD_PRESENTATION_DISMISSED];
          }];
     }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pageWidth = scrollView.frame.size.width;
    NSInteger candidateCardNumber = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    // Bounce past either end of the deck must not index outside the cards.
    NSUInteger visibleCardNumber = (NSUInteger)MAX(0, MIN(candidateCardNumber, (NSInteger)self.presentationCards.count - 1));
    self.cardIndexIndicator.currentPage = visibleCardNumber;
    
    if (visibleCardNumber > self.indexOfFurthestViewedCard)
    {
        self.indexOfFurthestViewedCard = visibleCardNumber;
    }
    
    id<DGPresentationCardProtocol> visibleCard = [self.presentationCards objectAtIndex:visibleCardNumber];
    if (![self.visibleCard isEqual:visibleCard])
    {
        [visibleCard cardBecameActive];
        [self drawHighlightRegion:visibleCard.highlightRegion roundingRadius:5.0f];
        self.visibleCard = visibleCard;
    }
}

@end
