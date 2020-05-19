//
//  KDDownloadModel.h
//  KDDownloadManager
//
//  Created by 范魁东 on 2020/5/19.
//  Copyright © 2020 FanKD. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, KDDownloadState) {
    KDDownloadStateDefault = 0,  // 默认
    KDDownloadStateDownloading,  // 正在下载
    KDDownloadStateWaiting,      // 等待
    KDDownloadStatePaused,       // 暂停
    KDDownloadStateFinish,       // 完成
    KDDownloadStateError,        // 错误
};

NS_ASSUME_NONNULL_BEGIN

#define kVideoCacheDirectory  [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]

@interface KDDownloadModel : NSObject

@property (nonatomic, copy) NSString *localPath;            // 下载完成路径
@property (nonatomic, copy) NSString *vid;                  // 文件唯一id标识
@property (nonatomic, copy) NSString *fileName;             // 文件名
@property (nonatomic, copy) NSString *thumbUrl;             // 封面
@property (nonatomic, copy) NSString *url;                  // url
@property (nonatomic, strong) NSData *resumeData;           // 下载的数据
@property (nonatomic, assign) CGFloat progress;             // 下载进度
@property (nonatomic, assign) KDDownloadState state;        // 下载状态
@property (nonatomic, assign) NSUInteger totalFileSize;     // 文件总大小
@property (nonatomic, assign) NSUInteger tmpFileSize;       // 下载大小
@property (nonatomic, assign) NSUInteger speed;             // 下载速度
@property (nonatomic, assign) NSTimeInterval lastSpeedTime; // 上次计算速度时的时间戳
@property (nonatomic, assign) NSUInteger intervalFileSize;  // 计算速度时间内下载文件的大小
@property (nonatomic, assign) NSUInteger lastStateTime;     // 记录任务加入准备下载的时间（点击默认、暂停、失败状态），用于计算开始、停止任务的先后顺序

// 根据数据库查询结果初始化
- (instancetype)initWithFMResultSet:(FMResultSet *)resultSet;


@end

NS_ASSUME_NONNULL_END
