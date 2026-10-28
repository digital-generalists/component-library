//
//  DGShelfViewController.m
//  DGCoreUI
//
//  Created by Mark Johnson on 6/19/12.
//  Copyright (c) 2012 Digital Generalists, LLC. All rights reserved.
//

#import "DGShelfViewController.h"

#import <DGCoreUI/DGComponentTypeDefinitions.h>

@interface DGShelfViewController ()

@end

@implementation DGShelfViewController

@synthesize host = _host;

- (id)initWithHost:(UIViewController *)host
{
    // The view hierarchy is built in code, so no host storyboard is required.
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _host = host;
    }
    return self;
}

- (id) initWithHost:(UIViewController *)host containerViewController:(UIViewController *)containerViewController
{
    return [self initWithHost:host];
}

- (void) attachToContainerViewController:(UIViewController *)containerViewController
{
    // Can safely ignore.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) transitionToSupportViewMode:(DGSupportViewMode)newMode
{
    // Can safely ignore.
}

@end
