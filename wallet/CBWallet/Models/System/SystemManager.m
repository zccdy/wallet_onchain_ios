//
//  SystemManager.m
//  wallet
//
//  Created by Zin on 16/2/24.
//  Copyright © 2016年 Bitmain. All rights reserved.
//

#import "SystemManager.h"
#import "SSKeychain.h"

@implementation SystemManager

+ (instancetype)defaultManager {
    static id staticInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        staticInstance = [[self alloc] init];
    });
    return staticInstance;
}

- (BOOL)isWalletInstalled {
#warning 未测试方便，每次都会清理已注册密码
    [SSKeychain deletePasswordForService:CBWKeyChainSeedService account:CBWKeyChainAccountDefault];
    NSData *seed = [SSKeychain passwordDataForService:CBWKeyChainSeedService account:CBWKeyChainAccountDefault];
    if (seed) {
        return YES;
    }
    return NO;
}

- (BOOL)isiCloudAccountSignedIn {
    if ([NSFileManager defaultManager].ubiquityIdentityToken) {
        return YES;
    }
    return NO;
}

@end