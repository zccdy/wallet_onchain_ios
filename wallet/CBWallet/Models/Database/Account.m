//
//  Account.m
//  wallet
//
//  Created by Zin on 16/2/24.
//  Copyright © 2016年 Bitmain. All rights reserved.
//

#import "Account.h"
#import "AccountStore.h"

NSString *const AccountWathcedOnlyLabel = @"Watched Only Account";
const NSInteger AccountWatchedOnlyIdx = -1;

@implementation Account

- (void)setIdx:(NSInteger)idx {
    if (_idx != idx) {
        _idx = idx;
    }
}

+ (instancetype)newAccountWithIdx:(NSInteger)idx label:(NSString *)label inStore:(AccountStore *)store {
    Account *account = [self newRecordInStore:store];
    account.idx = idx;
    account.label = label;
    return account;
}

+ (instancetype)accountWatchedOnly {
    Account *account = [[Account alloc] init];
    account.idx = AccountWatchedOnlyIdx;
    account.label = AccountWathcedOnlyLabel;
    return account;
}

//- (void)deleteFromStore:(RecordObjectStore *)store {
//    DLog(@"will never delete an account");
//    return;
//}

- (void)saveWithError:(NSError *__autoreleasing  _Nullable *)error {
    [[DatabaseManager defaultManager] saveAccount:self];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"account %@: idx = %ld", self.label, (long)self.idx];
}

@end