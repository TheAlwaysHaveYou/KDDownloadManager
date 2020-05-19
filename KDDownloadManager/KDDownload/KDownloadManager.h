//
//  KDownloadManager.h
//  KDDownloadManager
//
//  Created by 范魁东 on 2020/5/19.
//  Copyright © 2020 FanKD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDDownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDownloadManager : NSObject

+ (instancetype)sharedInstance;

//准备下载
- (void)prepareDownloadTask:(KDDownloadModel *)model statusString:(void(^)(NSString *string))prepareBlock;

// 开始下载
- (void)startDownloadTask:(KDDownloadModel *)model;

// 暂停下载
- (void)pauseDownloadTask:(KDDownloadModel *)model;

// 删除下载任务及本地缓存
- (void)deleteTaskAndCache:(KDDownloadModel *)model;

//删除所有下载内容
- (void)deleteAllTaskAndCacheDate;

@end

NS_ASSUME_NONNULL_END
