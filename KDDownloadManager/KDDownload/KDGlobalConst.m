//
//  KDGlobalConst.m
//  KDDownloadManager
//
//  Created by 范魁东 on 2020/5/19.
//  Copyright © 2020 FanKD. All rights reserved.
//

#import <Foundation/Foundation.h>

/************************* 下载 *************************/
NSString * const KDDownloadProgressNotification                   = @"KDDownloadProgressNotification";
NSString * const KDDownloadStateChangeNotification                = @"KDDownloadStateChangeNotification";
NSString * const KDDownloadMaxConcurrentCountKey                  = @"KDDownloadMaxConcurrentCountKey";
NSString * const KDDownloadMaxConcurrentCountChangeNotification   = @"KDDownloadMaxConcurrentCountChangeNotification";
NSString * const KDDownloadAllowsCellularAccessKey                = @"KDDownloadAllowsCellularAccessKey";
NSString * const KDDownloadAllowsCellularAccessChangeNotification = @"KDDownloadAllowsCellularAccessChangeNotification";

/************************* 网络 *************************/
NSString * const KDNetworkingReachabilityDidChangeNotification     = @"KDNetworkingReachabilityDidChangeNotification";

/************************* 程序终结（手动终结，异常崩溃） *************************/
NSString * const AppOccurCashOrTerminateNotification = @"AppOccurCashOrTerminateNotification";
