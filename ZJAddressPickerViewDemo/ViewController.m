//
//  ViewController.m
//  ZJAddressPickerViewDemo
//
//  Created by Abnerzj on 2023/5/12.
//

#import "ViewController.h"
#import "ZJAddressPickerView.h"

/*
 1，修复往回选择时数据错乱问题
 2，增加修改地址功能
 3，支持从网络加载数据回传
 4，已经选择最后一级不再继续拉取调整标题和表格
 5，数据不够时用空数据处理，避免数组越界错误
 */

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *button;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)buttonClick:(UIButton *)sender {
    ZJAddressConfig *addressConfig = [ZJAddressConfig new];
    
    // 可选级别（默认4级，可达5级，本地数据源只支持4级联动数据）
    addressConfig.maxLevels = 4;
    // 标题
    addressConfig.title = @"请选择地址";
    // 取消按钮
    addressConfig.cancel = @"取消";
    // 主题色
    addressConfig.themColor = UIColor.redColor;
    // 文本颜色
    addressConfig.textColor = UIColor.blackColor;
    // 选中结果文本颜色
    addressConfig.selectTextColor = UIColor.redColor;
    // 设置是否线条渐变,跟themColor相关连
    addressConfig.isGradientLine = YES;
    // 弹窗高度
    addressConfig.viewHeight = 400;
    
    ZJAddressPickerView *addressView = [ZJAddressPickerView new];
    addressView.addressConfig = addressConfig;
    
//    // 从网络加载数据，用户自定义实现
//    [self loadNetworkData:^(NSArray<ZJAreaData *> *list) {
//        addressView.areaProvider.sourceList = list;
//    }];
    
    // 已选择的地址数据
//    addressView.areaProvider.selectedSources = @[@"广东省", @"深圳市", @"南山区", @"粤海街道"];
//    addressView.areaProvider.selectedSources = [[self.button titleForState:UIControlStateNormal] componentsSeparatedByString:@" "];
    
    // 选择完地址数据后回调
    __weak typeof(self) ws = self;
    addressView.completion = ^(NSArray<ZJAreaData *> * _Nonnull list) {
        __strong typeof(self) self = ws;
        NSMutableString *address = [NSMutableString new];
        [list enumerateObjectsUsingBlock:^(ZJAreaData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.name isEqualToString:@""]) {
                NSLog(@"联动数据不够，已用空数据处理");
            }
            [address appendString:obj.name];
            if (idx < list.count - 1) {
                [address appendString:@" "];
            }
        }];
        NSLog(@"address = %@", address);
        [self.button setTitle:address forState:UIControlStateNormal];
    };
    
    // 显示
    [addressView show];
}

- (void)loadNetworkData:(void(^)(NSArray<ZJAreaData *> *list))callback {
    //这里替换成自己的网络数据加载方案
    /*
     [AFN POST:url param: @{@"code": areaId} callback:^(id response){
        if (response.result) {
             if (callback) {
                callback(response.result);
             }
        }
     }];
     */
}

@end
