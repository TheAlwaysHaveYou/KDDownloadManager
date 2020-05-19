//
//  ViewController.m
//  KDDownloadManager
//
//  Created by 范魁东 on 2020/5/19.
//  Copyright © 2020 FanKD. All rights reserved.
//

#import "ViewController.h"
#import "AFDownloadCell.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic , strong) UITableView *tableView;
@property (nonatomic , strong) NSMutableArray <KDDownloadModel *> *sourceArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *titleArr = @[@"高清图片包1",@"高清图片包2",@"高清图片包3",@"QQ安装包",@"会计概述一",@"会计概述二",@"资产一",@"资产二",@"资产三"];
    
    NSArray *urlArr = @[@"http://fjdx.sc.chinaz.net/Files/DownLoad/pic9/201907/hpic1264.rar",
                        @"http://fjdx.sc.chinaz.net/Files/DownLoad/pic9/201907/bpic12888.rar",
                        @"http://fjdx.sc.chinaz.net/Files/DownLoad/pic9/201907/zzpic19269.rar",
                        @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.2.4.dmg",
                        @"http://v.zaixue.cn/ZX_video/f797bad7e3984b5bb84987e3a0debe62/fd_1553914599756/Z_cjkj_sw_xtb_19_1_th.mp4",
                        @"http://v.zaixue.cn/ZX_video/a8e8bf526d91437d8618f5f936e50066/fd_1553914599756/Z_cjkj_sw_xtb_19_2_th.mp4",
                        @"http://v.zaixue.cn/ZX_video/3fb8cb2e53dc4ba9b6dc767bbbf4d3e8/fd_1553914599756/Z_cjkj_sw_xtb_19_3_th.mp4",
                        @"http://v.zaixue.cn/ZX_video/616096fa209a41f49199b87b901cb484/fd_1553914599756/Z_cjkj_sw_xtb_19_4_th.mp4",
                        @"http://v.zaixue.cn/ZX_video/76fc8758168846f6a03f0eae385646ca/fd_1553914599756/Z_cjkj_sw_xtb_19_6_th.mp4"];
    NSMutableArray *tempArr = [NSMutableArray arrayWithCapacity:0];
    [titleArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        KDDownloadModel *model = [[KDDownloadModel alloc] init];
        model.fileName = obj;
        model.url = urlArr[idx];
        model.thumbUrl = @"";
        model.vid = @"id+";
        [tempArr addObject:model];
    }];
    
    self.sourceArr = tempArr;
    
    NSArray *cacheData = [[KDDataBaseManager shareManager] getAllCacheData];
    for (int i = 0; i < self.sourceArr.count; i++) {
        KDDownloadModel *model = self.sourceArr[i];
        for (KDDownloadModel *downloadModel in cacheData) {
            if ([model.url isEqualToString:downloadModel.url]) {
                self.sourceArr[i] = downloadModel;
                break;
            }
        }
    }
    
    [self.view addSubview:self.tableView];
    
    [self addNotification];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height-64) style:UITableViewStylePlain];
        [_tableView registerClass:[AFDownloadCell class] forCellReuseIdentifier:@"cell"];
        _tableView.rowHeight = 80;
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (void)addNotification
{
    // 进度通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downLoadProgress:) name:KDDownloadProgressNotification object:nil];
    // 状态改变通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downLoadStateChange:) name:KDDownloadStateChangeNotification object:nil];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sourceArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AFDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.model = self.sourceArr[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (UITableViewCellEditingStyleDelete == editingStyle) {
        KDDownloadModel *downloadModel = self.sourceArr[indexPath.row];
        
        [[KDownloadManager sharedInstance] deleteTaskAndCache:downloadModel];
        [self.sourceArr removeObject:downloadModel];
        [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - HWDownloadNotification
// 正在下载，进度回调
- (void)downLoadProgress:(NSNotification *)notification {
    KDDownloadModel *downloadModel = notification.object;
    
    [self.sourceArr enumerateObjectsUsingBlock:^(KDDownloadModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.url isEqualToString:downloadModel.url]) {
            // 主线程更新cell进度
            dispatch_async(dispatch_get_main_queue(), ^{
                AFDownloadCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
                [cell updateViewWithModel:downloadModel];
            });
            
            *stop = YES;
        }
    }];
}

// 状态改变
- (void)downLoadStateChange:(NSNotification *)notification {
    KDDownloadModel *downloadModel = notification.object;
    
    [self.sourceArr enumerateObjectsUsingBlock:^(KDDownloadModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.url isEqualToString:downloadModel.url]) {
            // 更新数据源
            self.sourceArr[idx] = downloadModel;
            
            // 主线程刷新cell
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            });
            
            *stop = YES;
        }
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
