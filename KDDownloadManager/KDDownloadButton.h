//
//  KDDownloadButton.h
//  KDDownloadManager
//
//  Created by 范魁东 on 2020/5/19.
//  Copyright © 2020 FanKD. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KDDownloadButton : UIView

@property (nonatomic, strong) KDDownloadModel *model;  // 数据模型
@property (nonatomic, assign) KDDownloadState state;   // 下载状态
@property (nonatomic, assign) CGFloat progress;        // 下载进度

// 添加点击方法
- (void)addTarget:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
