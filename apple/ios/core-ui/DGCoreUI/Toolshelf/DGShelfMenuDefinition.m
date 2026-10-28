//
//  DGShelfMenuDefinition.m
//  DGCoreUI
//
//  Created by Mark Johnson on 10/25/26.
//  Copyright (c) 2026 Digital Generalists, LLC. All rights reserved.
//

#import "DGShelfMenuDefinition.h"

@interface DGShelfMenuDefinition ()

@property (readwrite, copy, nonatomic) NSString *name;
@property (readwrite, strong, nonatomic) UIButton *menuButton;
@property (readwrite, copy, nonatomic) NSArray<UIButton *> *buttons;
@property (readwrite, copy, nonatomic) NSArray<UIButton *> *buttonsIgnoringDoubleTap;

@end

@implementation DGShelfMenuDefinition

@synthesize name = _name;
@synthesize menuButton = _menuButton;
@synthesize buttons = _buttons;
@synthesize buttonsIgnoringDoubleTap = _buttonsIgnoringDoubleTap;

- (id) initWithName:(NSString *)name menuButton:(UIButton *)menuButton buttons:(NSArray<UIButton *> *)buttons
{
    return [self initWithName:name menuButton:menuButton buttons:buttons buttonsIgnoringDoubleTap:nil];
}

- (id) initWithName:(NSString *)name menuButton:(UIButton *)menuButton buttons:(NSArray<UIButton *> *)buttons buttonsIgnoringDoubleTap:(NSArray<UIButton *> *)buttonsIgnoringDoubleTap
{
    self = [super init];
    if (self)
    {
        self.name = name;
        self.menuButton = menuButton;
        self.buttons = (buttons ? buttons : @[]);
        self.buttonsIgnoringDoubleTap = (buttonsIgnoringDoubleTap ? buttonsIgnoringDoubleTap : @[]);
    }
    return self;
}

@end
