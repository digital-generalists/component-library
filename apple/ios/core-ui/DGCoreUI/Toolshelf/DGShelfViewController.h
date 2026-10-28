//
//  DGShelfViewController.h
//  DGCoreUI
//
//  Created by Mark Johnson on 6/19/12.
//  Copyright (c) 2012 Digital Generalists, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DGCoreUI/DGSupportViewControllerProtocol.h>

@interface DGShelfViewController : UIViewController<DGSupportViewControllerProtocol>

@property (readonly, nonatomic) UIViewController *host;

@end
