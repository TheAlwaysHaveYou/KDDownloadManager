//
//  KDGlobalConst.h
//  KDDownloadManager
//
//  Created by 范魁东 on 2020/5/19.
//  Copyright © 2020 FanKD. All rights reserved.
//

#import <UIKit/UIKit.h>

/************************* 下载 *************************/
UIKIT_EXTERN NSString * const KDDownloadProgressNotification;                   // 进度回调通知
UIKIT_EXTERN NSString * const KDDownloadStateChangeNotification;                // 状态改变通知
UIKIT_EXTERN NSString * const KDDownloadMaxConcurrentCountKey;                  // 最大同时下载数量key
UIKIT_EXTERN NSString * const KDDownloadMaxConcurrentCountChangeNotification;   // 最大同时下载数量改变通知
UIKIT_EXTERN NSString * const KDDownloadAllowsCellularAccessKey;                // 是否允许蜂窝网络下载key
UIKIT_EXTERN NSString * const KDDownloadAllowsCellularAccessChangeNotification; // 是否允许蜂窝网络下载改变通知

/************************* 网络 *************************/
UIKIT_EXTERN NSString * const KDNetworkingReachabilityDidChangeNotification;    // 网络改变改变通知


/************************* 程序终结（手动终结，异常崩溃） *************************/
UIKIT_EXTERN NSString * const AppOccurCashOrTerminateNotification;    // 程序终结

