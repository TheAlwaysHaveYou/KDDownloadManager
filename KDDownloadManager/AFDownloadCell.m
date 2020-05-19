//
//  AFDownloadCell.m
//  KDDownloadManager
//
//  Created by 范魁东 on 2020/5/19.
//  Copyright © 2020 FanKD. All rights reserved.
//

#import "AFDownloadCell.h"
#import "KDDownloadButton.h"

@interface AFDownloadCell ()

@property (nonatomic, weak) UILabel *titleLabel;            // 标题
@property (nonatomic, weak) UILabel *speedLabel;            // 进度标签
@property (nonatomic, weak) UILabel *fileSizeLabel;         // 文件大小标签
@property (nonatomic, weak) KDDownloadButton *downloadBtn;  // 下载按钮

@end

@implementation AFDownloadCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // 底图
        CGFloat margin = 10.f;
        CGFloat backViewH = 70.f;
        UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(0, margin * 0.5, KMainW - margin * 2, backViewH)];
        backView.backgroundColor = [UIColor grayColor];
        [self.contentView addSubview:backView];
        
        // 下载按钮
        CGFloat btnW = 50.f;
        KDDownloadButton *downloadBtn = [[KDDownloadButton alloc] initWithFrame:CGRectMake(backView.frame.size.width - btnW - margin, (backViewH - btnW) * 0.5, btnW, btnW)];
        [downloadBtn addTarget:self action:@selector(downBtnOnClick:)];
        [backView addSubview:downloadBtn];
        _downloadBtn = downloadBtn;
        
        // 标题
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, 0, backView.frame.size.width - margin * 3 - btnW, backViewH * 0.6)];
        titleLabel.font = [UIFont boldSystemFontOfSize:18.f];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = backView.backgroundColor;
        titleLabel.layer.masksToBounds = YES;
        [backView addSubview:titleLabel];
        _titleLabel = titleLabel;
        
        // 进度标签
        UILabel *speedLable = [[UILabel alloc] initWithFrame:CGRectMake(margin, CGRectGetMaxY(titleLabel.frame), titleLabel.frame.size.width * 0.36, backViewH * 0.4)];
        speedLable.font = [UIFont systemFontOfSize:14.f];
        speedLable.textColor = [UIColor whiteColor];
        speedLable.textAlignment = NSTextAlignmentRight;
        speedLable.backgroundColor = backView.backgroundColor;
        speedLable.layer.masksToBounds = YES;
        [backView addSubview:speedLable];
        _speedLabel = speedLable;
        
        // 文件大小标签
        UILabel *fileSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(speedLable.frame), CGRectGetMaxY(titleLabel.frame), titleLabel.frame.size.width - speedLable.frame.size.width, backViewH * 0.4)];
        fileSizeLabel.font = [UIFont systemFontOfSize:14.f];
        fileSizeLabel.textColor = [UIColor whiteColor];
        fileSizeLabel.textAlignment = NSTextAlignmentRight;
        fileSizeLabel.backgroundColor = backView.backgroundColor;
        fileSizeLabel.layer.masksToBounds = YES;
        [backView addSubview:fileSizeLabel];
        _fileSizeLabel = fileSizeLabel;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    
    
}

- (void)setModel:(KDDownloadModel *)model
{
    _model = model;
    
    _downloadBtn.model = model;
    _titleLabel.text = model.fileName;
    [self updateViewWithModel:model];
}

// 更新视图
- (void)updateViewWithModel:(KDDownloadModel *)model
{
    _downloadBtn.progress = model.progress;
    
    [self reloadLabelWithModel:model];
}

// 刷新标签
- (void)reloadLabelWithModel:(KDDownloadModel *)model
{
    NSString *totalSize = [KDTool stringFromByteCount:model.totalFileSize];
    NSString *tmpSize = [KDTool stringFromByteCount:model.tmpFileSize];
    
    if (model.state == KDDownloadStateFinish) {
        _fileSizeLabel.text = [NSString stringWithFormat:@"%@", totalSize];
        
    }else {
        _fileSizeLabel.text = [NSString stringWithFormat:@"%@ / %@", tmpSize, totalSize];
    }
    _fileSizeLabel.hidden = model.totalFileSize == 0;
    
    if (model.speed > 0) {
        _speedLabel.text = [NSString stringWithFormat:@"%@ / s", [KDTool stringFromByteCount:model.speed]];
    }
    _speedLabel.hidden = !(model.state == KDDownloadStateDownloading && model.totalFileSize > 0);
}

- (void)downBtnOnClick:(KDDownloadButton *)btn
{
    // do something...
}

@end
