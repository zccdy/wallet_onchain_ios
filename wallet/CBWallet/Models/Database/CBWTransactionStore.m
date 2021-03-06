//
//  TransactionStore.m
//  CBWallet
//
//  Created by Zin (noteon.com) on 16/3/25.
//  Copyright © 2016年 Bitmain. All rights reserved.
//

#import "CBWTransactionStore.h"
#import "CBWAccount.h"

#import "NSDate+Helper.h"

@interface CBWTransactionStore ()

/// array of days
@property (nonatomic, strong) NSMutableArray<NSString *> *sections;
/// dictionary with day: transactions
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<CBWTransaction *> *> *rows;

@end

@implementation CBWTransactionStore

- (NSMutableArray *)sections {
    if (!_sections) {
        _sections = [[NSMutableArray alloc] init];
    }
    return _sections;
}

- (NSMutableDictionary *)rows {
    if (!_rows) {
        _rows = [[NSMutableDictionary alloc] init];
    }
    return _rows;
}

- (NSInteger)insertTransactionsFromCollection:(id)collection {
    if (![collection isKindOfClass:[NSArray class]] && ![collection isKindOfClass:[NSDictionary class]]) {
        return 0;
    }
    if ([self.delegate respondsToSelector:@selector(transactionStoreWillUpdate:)]) {
        [self.delegate transactionStoreWillUpdate:self];
    }
    
    __block NSMutableArray<CBWTransaction *> *transactions = [NSMutableArray array];
    if ([collection isKindOfClass:[NSDictionary class]]) {
        CBWTransaction *transaction = [[CBWTransaction alloc] initWithDictionary:collection];
        [transactions addObject:transaction];
    } else if ([collection isKindOfClass:[NSArray class]]) {
        [collection enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                CBWTransaction *transaction = [[CBWTransaction alloc] initWithDictionary:obj];
                [transactions addObject:transaction];
            }
        }];
    }
    // check and save
    __block NSInteger insertedCount = 0;
    NSUInteger count = transactions.count;
    [transactions enumerateObjectsUsingBlock:^(CBWTransaction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        insertedCount ++;
        [self p_addTransaction:obj];
        if (idx == count - 1) {
            DLog(@"Last one");
            if ([self.delegate respondsToSelector:@selector(transactionStoreDidUpdate:)]) {
                [self.delegate transactionStoreDidUpdate:self];
            }
        }
    }];
    return insertedCount;
}



- (void)flush {
    [super flush];
    [self.rows removeAllObjects];
    [self.sections removeAllObjects];
    if ([self.delegate respondsToSelector:@selector(transactionStoreDidUpdate:)]) {
        [self.delegate transactionStoreDidUpdate:self];
    }
}

- (NSUInteger)numberOfSections {
    return self.sections.count;
}

- (NSUInteger)numberOfRowsInSection:(NSUInteger)section {
    if (section < self.numberOfSections) {
        return [[self.rows objectForKey:[self.sections objectAtIndex:section]] count];
    }
    return 0;
}

- (NSString *)dayInSection:(NSUInteger)section {
    if (section < self.numberOfSections) {
        return [self.sections objectAtIndex:section];
    }
    return nil;
}

- (CBWTransaction *)transactionAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section = indexPath.section;
    NSString *day = [self dayInSection:section];
    if (day) {
        NSArray *sectionDatas = [self.rows objectForKey:day];
        NSUInteger row = indexPath.row;
        if (row < sectionDatas.count) {
            return [sectionDatas objectAtIndex:row];
        }
    }
    return nil;
}

- (BOOL)addRecord:(__kindof CBWRecordObject *)record ASC:(BOOL)ASC {
    if (![super addRecord:record ASC:ASC]) {
        if (!record) {
            return NO;
        }
        // 存在重复的交易
        DLog(@"transaction exist");
        // 检查确认数是否变化
        CBWTransaction *newTransaction = record;
        __block CBWTransaction *existedTransaction = nil;
        [records enumerateObjectsUsingBlock:^(__kindof CBWRecordObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CBWTransaction *transaction = obj;
            if ([transaction isEqual:newTransaction]) {
                existedTransaction = transaction;
                *stop = YES;
            }
        }];
        if (existedTransaction.confirmations == newTransaction.confirmations) {
            return NO;
        }
        
        // 旧交易时间
        NSDate *oldTransactionTime = [existedTransaction.transactionTime copy];
        
        // 更新 store
        [existedTransaction setValuesForKeysWithDictionary:@{@"confirmations": @(newTransaction.confirmations),
                                                             @"blockHeight": @(newTransaction.blockHeight),
                                                             @"blockTime": newTransaction.blockTime}];
        
        // 通知
        if ([self.delegate respondsToSelector:@selector(transactionStore:didUpdateRecord:atIndexPath:forChangeType:toNewIndexPath:)]) {
            // 根据旧交易时间获取原来的 index path
            NSString *day = [oldTransactionTime stringWithFormat:@"yyyy-MM-dd"];
            
            NSUInteger section = [self.sections indexOfObject:day];
            NSArray *rows = [self.rows objectForKey:day];
            NSUInteger row = [rows indexOfObject:existedTransaction];
            if (section != NSNotFound && row != NSNotFound) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                NSIndexPath *newIndexPath = indexPath;
                if (![oldTransactionTime isInSameDayWithDate:existedTransaction.transactionTime]) {
                    // 移除旧的
                    NSMutableArray *rows = [self.rows objectForKey:day];
                    [rows removeObject:existedTransaction];
                    if (rows.count == 0) {
                        [self.rows removeObjectForKey:day];
                        [self.sections removeObject:day];
                    }
                    // 添加新的
                    NSString *newDay = [existedTransaction.transactionTime stringWithFormat:@"yyyy-MM-dd"];
                    rows = [self p_dequeueReusableRowsAtDay:newDay];
                    [rows addObject:existedTransaction];
                    // 排序
                    [rows sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                        CBWTransaction *t1 = obj1;
                        CBWTransaction *t2 = obj2;
                        return [t2.transactionTime compare:t1.transactionTime];// DESC
                    }];
                    // 新的 index path
                    NSUInteger section = [self.sections indexOfObject:day];
                    NSUInteger row = [rows indexOfObject:existedTransaction];
                    if (section != NSNotFound && row != NSNotFound) {
                        newIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
                    }
                }
                [self.delegate transactionStore:self didUpdateRecord:existedTransaction atIndexPath:indexPath forChangeType:CBWTransactionStoreChangeTypeUpdate toNewIndexPath:newIndexPath];
            }
        }
        return NO;
    }
    
    return YES;

}

#pragma - Private Method

/// 加入 store
- (BOOL)p_addTransaction:(CBWTransaction *)transaction {
    if ([self addRecord:transaction ASC:YES]) {
        transaction.queryAddress = self.addressString;
        transaction.queryAddresses = @[self.addressString];
        [self p_didAddTransaction:transaction];
        return YES;
    }
    return NO;
}
/// 整理数据，按日期分组
- (void)p_didAddTransaction:(CBWTransaction *)transaction {
    NSString *day = [transaction.transactionTime stringWithFormat:@"yyyy-MM-dd"];
    NSMutableArray<CBWTransaction *> *rows = [self p_dequeueReusableRowsAtDay:day];
    NSInteger section = [self.sections indexOfObject:day];
    if (![rows containsObject:transaction]) {
        [rows addObject:transaction];
        [rows sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            CBWTransaction *t1 = obj1;
            CBWTransaction *t2 = obj2;
            return [t2.transactionTime compare:t1.transactionTime];// DESC
        }];
    }
    NSInteger row = [rows indexOfObject:transaction];
    
    if (rows.count == 1) {
        // new section
        if ([self.delegate respondsToSelector:@selector(transactionStore:didInsertSection:atIndex:)]) {
            [self.delegate transactionStore:self didInsertSection:day atIndex:section];
        }
    } else {
        // insert row to section
        if ([self.delegate respondsToSelector:@selector(transactionStore:didUpdateRecord:atIndexPath:forChangeType:toNewIndexPath:)]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            [self.delegate transactionStore:self didUpdateRecord:transaction atIndexPath:indexPath forChangeType:CBWTransactionStoreChangeTypeInsert toNewIndexPath:indexPath];
        }
    }
}


//- (NSInteger)p_dequeueReusableRows:(inout NSMutableArray<CBWTransaction *> *)rows atDay:(NSString *)day {
//    if (![self.sections containsObject:day]) {
//        // 新建
//        [self.sections addObject:day];
//        // 排序
//        [self.sections sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
//            NSDate *d1 = [NSDate dateFromString:obj1 withFormat:@"yyyy-MM-dd"];
//            NSDate *d2 = [NSDate dateFromString:obj2 withFormat:@"yyyy-MM-dd"];
//            return [d2 compare:d1];// DESC
//        }];
//        NSMutableArray *array = [[NSMutableArray alloc] init];
//        [self.rows setObject:array forKey:day];
//    }
//    rows = [self.rows objectForKey:day];
//    return [self.sections indexOfObject:day];
//}

/// 找出排序过的日期对应的数据
- (NSMutableArray *)p_dequeueReusableRowsAtDay:(NSString *)day {
    if (![self.sections containsObject:day]) {
        // 新建
        [self.sections addObject:day];
        // 排序
        [self.sections sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSDate *d1 = [NSDate dateFromString:obj1 withFormat:@"yyyy-MM-dd"];
            NSDate *d2 = [NSDate dateFromString:obj2 withFormat:@"yyyy-MM-dd"];
            return [d2 compare:d1];// DESC
        }];
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [self.rows setObject:array forKey:day];
    }
    return [self.rows objectForKey:day];
}

@end
