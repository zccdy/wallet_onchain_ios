//
//  DatabaseManager.m
//  CBWallet
//
//  Created by Zin on 16/3/21.
//  Copyright © 2016年 Bitmain. All rights reserved.
//

#import "DatabaseManager.h"
#import "Guard.h"

NSString *const DatabaseManagerDBPath = @"cbwdb.ss";// sqlite storage

// tables
NSString *const DatabaseManagerTableAccount = @"account";
NSString *const DatabaseManagerTableAddress = @"address";
NSString *const DatabaseManagerTableRecipient = @"recipient";

// columns
// common
NSString *const DatabaseManagerColRid = @"rid";
NSString *const DatabaseManagerColCreationDate = @"creationDate";
NSString *const DatabaseManagerColModificationDate = @"modificationDate";
NSString *const DatabaseManagerColIdx = @"idx";
NSString *const DatabaseManagerColAddress = @"address";
NSString *const DatabaseManagerColLabel = @"label";

// in account
NSString *const DatabaseManagerColCustomDefaultEnabled = @"customDefaultEnabled";

// in address
NSString *const DatabaseManagerColArchived = @"archived";
NSString *const DatabaseManagerColDirty = @"dirty";
NSString *const DatabaseManagerColBalance = @"balance";
NSString *const DatabaseManagerColTxCount = @"txCount";
NSString *const DatabaseManagerColAccountRid = @"accountRid";
NSString *const DatabaseManagerColAccountIdx = @"accountIdx";

@implementation DatabaseManager

+ (instancetype)defaultManager {
    static id staticInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        staticInstance = [[self alloc] init];
    });
    return staticInstance;
}

+ (FMDatabase *)installDb {
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dbPath = [documentDirectory stringByAppendingPathComponent:DatabaseManagerDBPath];
    return [FMDatabase databaseWithPath:dbPath];
}

- (FMDatabase *)db {
    if ([Guard globalGuard].code.length == 0) {
        NSLog(@"need check in to access database");
        return nil;
    }
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dbPath = [documentDirectory stringByAppendingPathComponent:DatabaseManagerDBPath];
    return [FMDatabase databaseWithPath:dbPath];
}

@end
