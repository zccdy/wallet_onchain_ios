//
//  Account.m
//  wallet
//
//  Created by Zin (noteon.com) on 16/2/24.
//  Copyright © 2016年 Bitmain. All rights reserved.
//

#import "CBWAccount.h"
#import "CBWAccountStore.h"

@implementation CBWAccount

- (void)setIdx:(NSInteger)idx {
    if (_idx != idx) {
        _idx = idx;
    }
}

+ (instancetype)newAccountWithIdx:(NSInteger)idx label:(NSString *)label inStore:(CBWAccountStore *)store {
    CBWAccount *account = [self newRecordInStore:store];
    account.idx = idx;
    account.label = label;
    return account;
}

//- (void)deleteFromStore:(RecordObjectStore *)store {
//    DLog(@"will never delete an account");
//    return;
//}

- (void)saveWithError:(NSError *__autoreleasing  _Nullable *)error {
    [[CBWDatabaseManager defaultManager] saveAccount:self];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"account %@: idx = %ld", self.label, (long)self.idx];
}

@end