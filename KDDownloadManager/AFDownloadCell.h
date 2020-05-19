//
//  AFDownloadCell.h
//  KDDownloadManager
//
//  Created by 范魁东 on 2020/5/19.
//  Copyright © 2020 FanKD. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KDDownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFDownloadCell : UITableViewCell

@property (nonatomic, strong) KDDownloadModel *model;

// 更新视图
- (void)updateViewWithModel:(KDDownloadModel *)model;


@end

NS_ASSUME_NONNULL_END
