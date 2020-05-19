//
//  KDDataBaseManager.h
//  KDDownloadManager
//
//  Created by 范魁东 on 2020/5/19.
//  Copyright © 2020 FanKD. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN



NS_ASSUME_NONNULL_END

typedef NS_OPTIONS(NSUInteger, KDDBUpdateOption) {
    KDDBUpdateOptionState         = 1 << 0,  // 更新状态
    KDDBUpdateOptionLastStateTime = 1 << 1,  // 更新状态最后改变的时间
    KDDBUpdateOptionResumeData    = 1 << 2,  // 更新下载的数据
    KDDBUpdateOptionProgressData  = 1 << 3,  // 更新进度数据（包含tmpFileSize、totalFileSize、progress、intervalFileSize、lastSpeedTime）
    KDDBUpdateOptionAllParam      = 1 << 4   // 更新全部数据
};

@class KDDownloadModel;
@interface KDDataBaseManager : NSObject

// 获取单例
+ (instancetype)shareManager;

// 插入数据
- (void)insertModel:(KDDownloadModel *)model;

// 获取数据
- (KDDownloadModel *)getModelWithUrl:(NSString *)url;    // 根据url获取数据
- (KDDownloadModel *)getWaitingModel;                    // 获取第一条等待的数据
- (KDDownloadModel *)getLastDownloadingModel;            // 获取最后一条正在下载的数据
- (NSArray<KDDownloadModel *> *)getAllCacheData;         // 获取所有数据
- (NSArray<KDDownloadModel *> *)getAllDownloadingData;   // 根据lastStateTime倒叙获取所有正在下载的数据
- (NSArray<KDDownloadModel *> *)getAllDownloadedData;    // 获取所有下载完成的数据
- (NSArray<KDDownloadModel *> *)getAllUnDownloadedData;  // 获取所有未下载完成的数据（包含正在下载、等待、暂停、错误）
- (NSArray<KDDownloadModel *> *)getAllWaitingData;       // 获取所有等待下载的数据

// 更新数据
- (void)updateWithModel:(KDDownloadModel *)model option:(KDDBUpdateOption)option;

// 删除数据
- (void)deleteModelWithUrl:(NSString *)url;

@end
