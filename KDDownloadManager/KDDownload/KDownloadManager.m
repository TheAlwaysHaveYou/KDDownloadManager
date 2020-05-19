//
//  KDownloadManager.m
//  KDDownloadManager
//
//  Created by 范魁东 on 2020/5/19.
//  Copyright © 2020 FanKD. All rights reserved.
//

#import "KDownloadManager.h"
#import "AppDelegate.h"
#import "KDDataBaseManager.h"
#import "KDTool.h"

@interface KDownloadManager ()

@property (nonatomic , strong) AFURLSessionManager *manager;

@property (nonatomic , strong) NSMutableDictionary *dataTaskDic;

@property (nonatomic , assign) NSInteger currentCount;                // 当前正在下载的个数
@property (nonatomic , assign) NSInteger maxConcurrentCount;          // 最大同时下载数量

@property (nonatomic, assign) BOOL allowsCellularAccess;             // 是否允许蜂窝网络下载

@end

@implementation KDownloadManager

+ (instancetype)sharedInstance {
    static KDownloadManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[KDownloadManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.dataTaskDic = [NSMutableDictionary dictionary];
        self.currentCount = 0;
        self.maxConcurrentCount = 1;
        
//        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.FKDownload.configurationIdentifier"];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.HTTPMaximumConnectionsPerHost = 4;//最大并发数
        configuration.allowsCellularAccess = YES;//蜂窝网络允许下载
        
        self.manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didCompleteDownloadNotification:)
                                                     name:AFNetworkingTaskDidCompleteNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFailToMoveFileNotification:)
                                                     name:AFURLSessionDownloadTaskDidFailToMoveFileNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(occurCashOrTerminateNotification:)
                                                     name:AppOccurCashOrTerminateNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(occurCashOrTerminateNotification:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkingReachabilityDidChange:)
                                                     name:AFNetworkingReachabilityDidChangeNotification
                                                   object:nil];
        
        //UIApplicationBackgroundRefreshStatusDidChangeNotification 后台下载状态发生改变时通知
        
        __weak typeof(self) weakSelf = self;
        [self.manager setDownloadTaskDidWriteDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            KDDownloadModel *model = [[KDDataBaseManager shareManager] getModelWithUrl:[downloadTask.currentRequest.URL absoluteString]];
            
            // 更新当前下载大小
            model.tmpFileSize = (NSUInteger)totalBytesWritten;
            model.totalFileSize = (NSUInteger)totalBytesExpectedToWrite;
            
            // 计算速度时间内下载文件的大小
            model.intervalFileSize += (NSUInteger)bytesWritten;
            
            // 获取上次计算时间与当前时间间隔
            NSInteger intervals = [KDTool getIntervalsWithTimeStamp:model.lastSpeedTime];
            if (intervals >= 1) {
                // 计算速度
                model.speed = model.intervalFileSize / intervals;
                // 重置变量
                model.intervalFileSize = 0;
                model.lastSpeedTime = [KDTool getTimeStampWithDate:[NSDate date]];
            }
            
            // 计算进度
            model.progress = 1.0 * model.tmpFileSize / model.totalFileSize;
            
            /*
             下面两步操作 是为了下载中app进程杀掉，再次启动而且后台还是没有下载完后，要更新数据
             后台接管在其启动app，要是还在下载，就要更新为ing状态
             */
            model.state = KDDownloadStateDownloading;
            [weakSelf.dataTaskDic setValue:downloadTask forKey:model.url];
            
            // 更新数据库中数据
            [[KDDataBaseManager shareManager] updateWithModel:model option:KDDBUpdateOptionProgressData];
            
            // 进度通知
            [[NSNotificationCenter defaultCenter] postNotificationName:KDDownloadProgressNotification object:model];
        }];

        [self.manager setDownloadTaskDidFinishDownloadingBlock:^NSURL * _Nullable(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, NSURL * _Nonnull location) {
            //返回自定义的存储路径， 下载完后 AF自动将文件移动到这个路径
            KDDownloadModel *model = [[KDDataBaseManager shareManager] getModelWithUrl:[downloadTask.currentRequest.URL absoluteString]];
            return [NSURL fileURLWithPath:model.localPath];
        }];
        
        [self.manager setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession * _Nonnull session) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            if (appDelegate.backgroundSessionCompletionHandler) {
                void (^completionHandler)(void) = appDelegate.backgroundSessionCompletionHandler;
                completionHandler();
                
                appDelegate.backgroundSessionCompletionHandler = nil;
            }
        }];
    }
    return  self;
}

#pragma mark - Notification

/***************************************下载模块的关键的代码 包括强退闪退都会有***************************************/
//下载停止的所有状态：取消，闪退，app进程结束，正常下载完成
- (void)didCompleteDownloadNotification:(NSNotification *)notification {
    NSLog(@"收到通知-----%@",notification.object);
    if ([notification.object isKindOfClass:[NSURLSessionDownloadTask class]]) {
        NSURLSessionDownloadTask *task = notification.object;
        NSError *error  = [notification.userInfo objectForKey:AFNetworkingTaskDidCompleteErrorKey] ;
        NSLog(@"通知的报错---%@",error);
        
        // 调用cancel方法直接返回，在相应操作是直接进行处理
//        if (error && [error.localizedDescription isEqualToString:@"cancelled"]) return;
        if(-999==error.code && [error.domain isEqualToString:NSURLErrorDomain]) return;
        
        // 获取模型
        KDDownloadModel *model = [[KDDataBaseManager shareManager] getModelWithUrl:[task.currentRequest.URL absoluteString]];
        
        // 下载时进程杀死，重新启动时回调错误
        if (error && [error.userInfo objectForKey:NSURLErrorBackgroundTaskCancelledReasonKey]) {
            model.state = KDDownloadStateWaiting;
            model.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            [[KDDataBaseManager shareManager] updateWithModel:model option:KDDBUpdateOptionState | KDDBUpdateOptionResumeData];
            return;
        }
        
        // 更新下载数据、任务状态
        if (error) {
            model.state = KDDownloadStateError;
            model.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            [[KDDataBaseManager shareManager] updateWithModel:model option:KDDBUpdateOptionResumeData];
        }else {
            model.state = KDDownloadStateFinish;
        }
        
        // 更新数据
        if (self.currentCount > 0) self.currentCount--;
        [self.dataTaskDic removeObjectForKey:model.url];
        
        // 更新数据库状态
        [[KDDataBaseManager shareManager] updateWithModel:model option:KDDBUpdateOptionState];
        
        // 开启等待下载任务
        [self startDownloadWaitingTask];
        NSLog(@"didCompleteDownloadNotification\n    文件：%@，didCompleteWithError\n    本地路径：%@ \n    错误：%@ \n", model.fileName, model.localPath, error);
    }
}

//现在完成后，移动缓存文件到目标地址出错， 出现的几率不大
- (void)didFailToMoveFileNotification:(NSNotification *)notification {
    NSLog(@"下载完成移动文件到目标路径出错---%@",notification.userInfo);
}
//程序终结
- (void)occurCashOrTerminateNotification:(NSNotification *)notification {
    NSLog(@"程序退出了~~~~~~");
    [self pauseDownloadingTaskWithAll:YES];
}

//网络状态改变
- (void)networkingReachabilityDidChange:(NSNotification *)notification {
    if ([notification.userInfo[AFNetworkingReachabilityNotificationStatusItem] isEqualToNumber: @(AFNetworkReachabilityStatusNotReachable)]) {
            // 无网络，暂停正在下载任务
            [self pauseDownloadingTaskWithAll:YES];
            
        }else {
            if ([self networkingAllowsDownloadTask]) {
                // 开启等待任务
                [self startDownloadWaitingTask];
                
            }else {
                // 增加一个友善的提示，蜂窝网络情况下如果有正在下载，提示已暂停
                if ([[KDDataBaseManager shareManager] getLastDownloadingModel]) {
                    //@"当前为蜂窝网络，已停止下载任务，可在设置中开启"
                }
                
                // 当前为蜂窝网络，不允许下载，暂停正在下载任务
                [self pauseDownloadingTaskWithAll:YES];
            }
        }
}

// 是否允许下载任务
- (BOOL)networkingAllowsDownloadTask {
    // 当前网络状态
    AFNetworkReachabilityStatus status = [[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus];

    // 无网络 或 （当前为蜂窝网络，且不允许蜂窝网络下载）
    if (status == AFNetworkReachabilityStatusNotReachable) {
        return NO;
    }
    
    return YES;
}


#pragma mark - Public
//准备下载
- (void)prepareDownloadTask:(KDDownloadModel *)model statusString:(void(^)(NSString *string))prepareBlock {
    KDDownloadModel *downloadModel = [[KDDataBaseManager shareManager] getModelWithUrl:model.url];
    if (downloadModel) {
        NSLog(@"已经存在于下载列表");
        if (prepareBlock) {
            prepareBlock(@"已经存在于下载列表");
        }
        return;
    }
    if (prepareBlock) {
        prepareBlock(@"已添加到下载任务列表");
    }
    [self startDownloadTask:model];
}

// 加入准备下载任务
- (void)startDownloadTask:(KDDownloadModel *)model {
    // 取出数据库中模型数据，如果不存在，添加到数据库中（注意：需要保证url唯一，若多条目同一url，则要另做处理）
    KDDownloadModel *downloadModel = [[KDDataBaseManager shareManager] getModelWithUrl:model.url];
    if (!downloadModel) {
        downloadModel = model;
        [[KDDataBaseManager shareManager] insertModel:downloadModel];
    }
    
    // 更新状态为等待下载
    downloadModel.state = KDDownloadStateWaiting;
    [[KDDataBaseManager shareManager] updateWithModel:downloadModel option:KDDBUpdateOptionState | KDDBUpdateOptionLastStateTime];
    
    // 下载（给定一个等待时间，保证currentCount更新）
    [NSThread sleepForTimeInterval:0.1f];
    if (self.currentCount < self.maxConcurrentCount) [self downloadwithModel:downloadModel];
}

// 开始下载
- (void)downloadwithModel:(KDDownloadModel *)model {
    self.currentCount ++;
    
    // cancelByProducingResumeData:回调有延时，给定一个等待时间，重新获取模型，保证获取到resumeData
    [NSThread sleepForTimeInterval:0.3f];
    KDDownloadModel *downloadModel = [[KDDataBaseManager shareManager] getModelWithUrl:model.url];
    
    // 更新状态为开始
    downloadModel.state = KDDownloadStateDownloading;
    [[KDDataBaseManager shareManager] updateWithModel:downloadModel option:KDDBUpdateOptionState];
    
    // 创建NSURLSessionDownloadTask
    NSURLSessionDownloadTask *downloadTask;
    if (downloadModel.resumeData) {
        downloadTask = [self.manager downloadTaskWithResumeData:downloadModel.resumeData progress:nil destination:nil completionHandler:nil];
    }else {
        downloadTask = [self.manager downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:downloadModel.url]] progress:nil destination:nil completionHandler:nil];
    }
    
    // 添加描述标签
//    downloadTask.taskDescription = downloadModel.url;
    
    // 更新存储的NSURLSessionDownloadTask对象
    [self.dataTaskDic setValue:downloadTask forKey:downloadModel.url];
    
    // 启动（继续下载）
    [downloadTask resume];
}


// 暂停下载
- (void)pauseDownloadTask:(KDDownloadModel *)model {
    // 取最新数据
    KDDownloadModel *downloadModel = [[KDDataBaseManager shareManager] getModelWithUrl:model.url];
    
    // 取消任务
    [self cancelTaskWithModel:downloadModel delete:NO];
    
    // 更新数据库状态为暂停
    downloadModel.state = KDDownloadStatePaused;
    [[KDDataBaseManager shareManager] updateWithModel:downloadModel option:KDDBUpdateOptionState];
}

// 删除下载任务及本地缓存
- (void)deleteTaskAndCache:(KDDownloadModel *)model
{
    // 如果正在下载，取消任务
    [self cancelTaskWithModel:model delete:YES];
    
    // 删除本地缓存、数据库数据
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NSFileManager defaultManager] removeItemAtPath:model.localPath error:nil];
        [[KDDataBaseManager shareManager] deleteModelWithUrl:model.url];
    });
}

//删除所有下载内容
- (void)deleteAllTaskAndCacheDate {
    NSArray <KDDownloadModel *> *dataSource = [[KDDataBaseManager shareManager] getAllCacheData];
    for (KDDownloadModel *model in dataSource) {
        [self deleteTaskAndCache:model];
    }
}

// 取消任务
- (void)cancelTaskWithModel:(KDDownloadModel *)model delete:(BOOL)delete {
    // 获取NSURLSessionDownloadTask
    NSURLSessionDownloadTask *downloadTask = [self.dataTaskDic valueForKey:model.url];

    if (model.state == KDDownloadStateDownloading) {
        // 取消任务 ,会调用父类的cancel 方法
        NSLog(@"准备取消");
        [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            // 更新下载数据
            model.resumeData = resumeData;
            [[KDDataBaseManager shareManager] updateWithModel:model option:KDDBUpdateOptionResumeData];
            NSLog(@"更新一下句柄------");
            // 更新当前正在下载的个数
            if (self.currentCount > 0) self.currentCount--;
            
            // 开启等待下载任务
            [self startDownloadWaitingTask];
        }];
        
        // 移除字典存储的对象
        if (delete) {
            [self.dataTaskDic removeObjectForKey:model.url];
        }
    }else {
        if (delete) {
            [downloadTask cancel];
        }
    }
    /*
     缓存清理优化部分
     */
    if (delete) {//删除沙盒tmp文件夹下面的临时文件，因为task cancel后，tmp里面的缓存还是一直在的，需要手动删除
        /*私有属性
         downloadTask->_downloadFile->_path:
         /Users/fankuidong/Library/Developer/CoreSimulator/Devices/F8867229-8F50-49C1-AFB8-2F8EBC857E69/data/Containers/Data/Application/152AE724-BAAF-4FB7-8463-A73BD6629FF3/tmp/CFNetworkDownload_b7tAvX.tmp
         */

        id file = [downloadTask valueForKey:@"_downloadFile"];
        NSString *path = [file valueForKey:@"_path"];
        if (path) {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (error) {
                NSLog(@"删除task缓存出错--%@",error.localizedDescription);
            }
        }
    }
}

// 开启等待下载任务
- (void)startDownloadWaitingTask {
    // 获取下一条等待的数据
    KDDownloadModel *model = [[KDDataBaseManager shareManager] getWaitingModel];
    
    if (model) {
        // 下载
        [self downloadwithModel:model];
        
        // 递归，开启下一个等待任务
        [self startDownloadWaitingTask];
    }
}

// 停止正在下载任务为等待状态
- (void)pauseDownloadingTaskWithAll:(BOOL)all {
    // 获取正在下载的数据
    NSArray *downloadingData = [[KDDataBaseManager shareManager] getAllDownloadingData];
    NSInteger count = all ? downloadingData.count : downloadingData.count - self.maxConcurrentCount;
    for (NSInteger i = 0; i < count; i++) {
        // 取消任务
        KDDownloadModel *model = downloadingData[i];
        [self cancelTaskWithModel:model delete:NO];
        
        // 更新状态为等待
        model.state = KDDownloadStateWaiting;
        [[KDDataBaseManager shareManager] updateWithModel:model option:KDDBUpdateOptionState];
    }
}

@end
