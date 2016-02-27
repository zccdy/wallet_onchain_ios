//
//  DashboardHeaderView.m
//  wallet
//
//  Created by Zin on 16/2/26.
//  Copyright © 2016年 Bitmain. All rights reserved.
//

#import "DashboardHeaderView.h"
#import "DashboardHeaderActionButton.h"

#import "UIButton+VerticalLayout.h"

@interface DashboardHeaderView ()

@property (nonatomic, weak, readwrite) UIButton *sendButton;
@property (nonatomic, weak, readwrite) UIButton *receiveButton;

@property (nonatomic, weak) UIView *overlayBackgroundView;

@end

@implementation DashboardHeaderView

- (UIButton *)sendButton {
    if (!_sendButton) {
        UIButton *button = [[DashboardHeaderActionButton alloc] initWithImage:[UIImage imageNamed:@"icon_send"] title:NSLocalizedStringFromTable(@"Button Send", @"BTCC", @"Send")];
        [button setTitleColor:[UIColor BTCCRedColor] forState:UIControlStateNormal];
        [self addSubview:button];
        _sendButton = button;
    }
    return _sendButton;
}


- (UIButton *)receiveButton {
    if (!_receiveButton) {
        UIButton *button = [[DashboardHeaderActionButton alloc] initWithImage:[UIImage imageNamed:@"icon_receive"] title:NSLocalizedStringFromTable(@"Button Receive", @"BTCC", @"Receive")];
        [button setTitleColor:[UIColor BTCCGreenColor] forState:UIControlStateNormal];
        [self addSubview:button];
        _receiveButton = button;
    }
    return _receiveButton;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.bounds;
    frame.size.width = CGRectGetWidth(frame) / 2.f;
    
    self.sendButton.frame = frame;
    [self.sendButton centerVerticallyWithPadding:BTCCLayoutInnerSpace];
    
    self.receiveButton.frame = CGRectOffset(frame, CGRectGetWidth(frame), 0);
    [self.receiveButton centerVerticallyWithPadding:BTCCLayoutInnerSpace];
    
    if (!_overlayBackgroundView) {
        CGFloat screenHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, -screenHeight, CGRectGetWidth(self.bounds), screenHeight + CGRectGetHeight(self.bounds))];
        view.backgroundColor = [UIColor BTCCSeparatorColor];
        [self insertSubview:view atIndex:0];
        _overlayBackgroundView = view;
    }
}

@end
