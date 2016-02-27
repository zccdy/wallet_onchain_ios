//
//  UIViewController+Appearance.m
//  wallet
//
//  Created by Zin on 16/2/27.
//  Copyright © 2016年 Bitmain. All rights reserved.
//

#import "UIViewController+Appearance.h"

@implementation UIViewController (Appearance)

- (void)setupAppearance {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    [self.navigationController.navigationBar setTintColor:[UIColor BTCCPrimaryColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor BTCCBlackColor]}];
//    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bar_tint_white"] forBarMetrics:UIBarMetricsDefault];
//    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    [self p_hideNavigationBarHairline];
    
    self.navigationController.view.backgroundColor = [UIColor BTCCBackgroundColor];
    
    self.view.backgroundColor = [UIColor BTCCBackgroundColor];
}

#pragma - Private Method
- (void)p_hideNavigationBarHairline {
    UIImageView *hairline = [self p_findHairlineImageViewUnder:self.navigationController.navigationBar];
    if (hairline) {
        hairline.alpha = 0.05;
    }
}
- (UIImageView *)p_findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self p_findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}
@end
