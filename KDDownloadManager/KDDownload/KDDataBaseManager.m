//
//  KDDataBaseManager.m
//  KDDownloadManager
//
//  Created by 范魁东 on 2020/5/19.
//  Copyright © 2020 FanKD. All rights reserved.
//

#import "KDDataBaseManager.h"
#import "KDTool.h"

typedef NS_ENUM(NSInteger, KDDBGetDateOption) {
    KDDBGetDateOptionAllCacheData = 0,      // 所有缓存数据
    KDDBGetDateOptionAllDownloadingData,    // 所有正在下载的数据
    KDDBGetDateOptionAllDownloadedData,     // 所有下载完成的数据
    KDDBGetDateOptionAllUnDownloadedData,   // 所有未下载完成的数据
    KDDBGetDateOptionAllWaitingData,        // 所有等待下载的数据
    KDDBGetDateOptionModelWithUrl,          // 通过url获取单条数据
    KDDBGetDateOptionWaitingModel,          // 第一条等待的数据
    KDDBGetDateOptionLastDownloadingModel,  // 最后一条正在下载的数据
};

@interface KDDataBaseManager ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation KDDataBaseManager

+ (instancetype)shareManager
{
    static KDDataBaseManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    
    return manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self creatVideoCachesTable];
    }
    
    return self;
}

// 创表
- (void)creatVideoCachesTable
{
    // 数据库文件路径
    
    NSString *path = [kVideoCacheDirectory stringByAppendingPathComponent:@"FKDownloadVideoInfoCaches.sqlite"];
//    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
//        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
//    }
    
    // 创建队列对象，内部会自动创建一个数据库, 并且自动打开
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    NSLog(@"缓存地址--%@",path);
    
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        // 创表
        BOOL result = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_videoCaches (id integer PRIMARY KEY AUTOINCREMENT, vid text, fileName text, thumbUrl text, url text, resumeData blob, totalFileSize integer, tmpFileSize integer, state integer, progress float, lastSpeedTime double, intervalFileSize integer, lastStateTime integer)"];
        if (result) {
            NSLog(@"视频缓存数据表创建成功");
        }else {
            NSLog(@"视频缓存数据表创建失败");
        }
        
        //更新数据库 ,插入封面字段
        if (![db columnExists:@"thumbUrl" inTableWithName:@"t_videoCaches"]) {
            BOOL final = [db executeUpdate:@"ALTER TABLE t_videoCaches ADD thumbUrl text"];
            if (final) {
                NSLog(@"成功插入新的字段");
            }else {
                NSLog(@"插入新的字段失败");
            }
        }
    }];
}

// 插入数据
- (void)insertModel:(KDDownloadModel *)model
{
    [_dbQueue inDatabase:^(FMDatabase *db) {
        BOOL result = [db executeUpdate:@"INSERT INTO t_videoCaches (vid, fileName, thumbUrl, url, resumeData, totalFileSize, tmpFileSize, state, progress, lastSpeedTime, intervalFileSize, lastStateTime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", model.vid, model.fileName, model.thumbUrl, model.url, model.resumeData, [NSNumber numberWithInteger:model.totalFileSize], [NSNumber numberWithInteger:model.tmpFileSize], [NSNumber numberWithInteger:model.state], [NSNumber numberWithFloat:model.progress], [NSNumber numberWithDouble:0], [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:0]];
        if (result) {
            NSLog(@"插入成功：%@", model.fileName);
        }else {
            NSLog(@"插入失败：%@", model.fileName);
        }
    }];
}

// 获取单条数据
- (KDDownloadModel *)getModelWithUrl:(NSString *)url
{
    return [self getModelWithOption:KDDBGetDateOptionModelWithUrl url:url];
}

// 获取第一条等待的数据
- (KDDownloadModel *)getWaitingModel
{
    return [self getModelWithOption:KDDBGetDateOptionWaitingModel url:nil];
}

// 获取最后一条正在下载的数据
- (KDDownloadModel *)getLastDownloadingModel
{
    return [self getModelWithOption:KDDBGetDateOptionLastDownloadingModel url:nil];
}

// 获取所有数据
- (NSArray<KDDownloadModel *> *)getAllCacheData
{
    return [self getDateWithOption:KDDBGetDateOptionAllCacheData];
}

// 根据lastStateTime倒叙获取所有正在下载的数据
- (NSArray<KDDownloadModel *> *)getAllDownloadingData
{
    return [self getDateWithOption:KDDBGetDateOptionAllDownloadingData];
}

// 获取所有下载完成的数据
- (NSArray<KDDownloadModel *> *)getAllDownloadedData
{
    return [self getDateWithOption:KDDBGetDateOptionAllDownloadedData];
}

// 获取所有未下载完成的数据
- (NSArray<KDDownloadModel *> *)getAllUnDownloadedData
{
    return [self getDateWithOption:KDDBGetDateOptionAllUnDownloadedData];
}

// 获取所有等待下载的数据
- (NSArray<KDDownloadModel *> *)getAllWaitingData
{
   return [self getDateWithOption:KDDBGetDateOptionAllWaitingData];
}

// 获取单条数据
- (KDDownloadModel *)getModelWithOption:(KDDBGetDateOption)option url:(NSString *)url
{
    __block KDDownloadModel *model = nil;
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet;
        switch (option) {
            case KDDBGetDateOptionModelWithUrl:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE url = ?", url];
                break;
                
            case KDDBGetDateOptionWaitingModel:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ? order by lastStateTime asc limit 0,1", [NSNumber numberWithInteger:KDDownloadStateWaiting]];
                break;
                
            case KDDBGetDateOptionLastDownloadingModel:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ? order by lastStateTime desc limit 0,1", [NSNumber numberWithInteger:KDDownloadStateDownloading]];
                break;
                
            default:
                break;
        }
        
        while ([resultSet next]) {
            model = [[KDDownloadModel alloc] initWithFMResultSet:resultSet];
        }
    }];
    
    return model;
}

// 获取数据集合
- (NSArray<KDDownloadModel *> *)getDateWithOption:(KDDBGetDateOption)option
{
    __block NSArray<KDDownloadModel *> *array = nil;
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet;
        switch (option) {
            case KDDBGetDateOptionAllCacheData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches"];
                break;
                
            case KDDBGetDateOptionAllDownloadingData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ? order by lastStateTime desc", [NSNumber numberWithInteger:KDDownloadStateDownloading]];
                break;
                
            case KDDBGetDateOptionAllDownloadedData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ?", [NSNumber numberWithInteger:KDDownloadStateFinish]];
                break;
                
            case KDDBGetDateOptionAllUnDownloadedData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state != ?", [NSNumber numberWithInteger:KDDownloadStateFinish]];
                break;
                
            case KDDBGetDateOptionAllWaitingData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ?", [NSNumber numberWithInteger:KDDownloadStateWaiting]];
                break;
                
            default:
                break;
        }
        
        NSMutableArray *tmpArr = [NSMutableArray array];
        while ([resultSet next]) {
            [tmpArr addObject:[[KDDownloadModel alloc] initWithFMResultSet:resultSet]];
        }
        array = tmpArr;
    }];
    
    return array;
}

// 更新数据
- (void)updateWithModel:(KDDownloadModel *)model option:(KDDBUpdateOption)option
{
    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (option & KDDBUpdateOptionState) {
            [self postStateChangeNotificationWithFMDatabase:db model:model];
            [db executeUpdate:@"UPDATE t_videoCaches SET state = ? WHERE url = ?", [NSNumber numberWithInteger:model.state], model.url];
        }
        if (option & KDDBUpdateOptionLastStateTime) {
            [db executeUpdate:@"UPDATE t_videoCaches SET lastStateTime = ? WHERE url = ?", [NSNumber numberWithInteger:[KDTool getTimeStampWithDate:[NSDate date]]], model.url];
        }
        if (option & KDDBUpdateOptionResumeData) {
            [db executeUpdate:@"UPDATE t_videoCaches SET resumeData = ? WHERE url = ?", model.resumeData, model.url];
        }
        if (option & KDDBUpdateOptionProgressData) {
            [db executeUpdate:@"UPDATE t_videoCaches SET state = ?, tmpFileSize = ?, totalFileSize = ?, progress = ?, lastSpeedTime = ?, intervalFileSize = ? WHERE url = ?", [NSNumber numberWithInteger:model.state], [NSNumber numberWithInteger:model.tmpFileSize], [NSNumber numberWithFloat:model.totalFileSize], [NSNumber numberWithFloat:model.progress], [NSNumber numberWithDouble:model.lastSpeedTime], [NSNumber numberWithInteger:model.intervalFileSize], model.url];
        }
        if (option & KDDBUpdateOptionAllParam) {
            [self postStateChangeNotificationWithFMDatabase:db model:model];
            [db executeUpdate:@"UPDATE t_videoCaches SET resumeData = ?, totalFileSize = ?, tmpFileSize = ?, progress = ?, state = ?, lastSpeedTime = ?, intervalFileSize = ?, lastStateTime = ? WHERE url = ?", model.resumeData, [NSNumber numberWithInteger:model.totalFileSize], [NSNumber numberWithInteger:model.tmpFileSize], [NSNumber numberWithFloat:model.progress], [NSNumber numberWithInteger:model.state], [NSNumber numberWithDouble:model.lastSpeedTime], [NSNumber numberWithInteger:model.intervalFileSize], [NSNumber numberWithInteger:[KDTool getTimeStampWithDate:[NSDate date]]], model.url];
        }
    }];
}

// 状态变更通知
- (void)postStateChangeNotificationWithFMDatabase:(FMDatabase *)db model:(KDDownloadModel *)model
{
    // 原状态
    NSInteger oldState = [db intForQuery:@"SELECT state FROM t_videoCaches WHERE url = ?", model.url];
    if (oldState != model.state && oldState != KDDownloadStateFinish) {
        // 状态变更通知
        [[NSNotificationCenter defaultCenter] postNotificationName:KDDownloadStateChangeNotification object:model];
    }
}

// 删除数据
- (void)deleteModelWithUrl:(NSString *)url
{
    [_dbQueue inDatabase:^(FMDatabase *db) {
        BOOL result = [db executeUpdate:@"DELETE FROM t_videoCaches WHERE url = ?", url];
        if (result) {
            NSLog(@"删除成功：%@", url);
        }else {
            NSLog(@"删除失败：%@", url);
        }
    }];
}

@end
