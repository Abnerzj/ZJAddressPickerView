//
//  ZJAddressPickerView.h
//  ZJAddressPickerViewDemo
//
//  Created by Abnerzj on 2023/5/12.
//

#import <UIKit/UIKit.h>
#import "ZJAreaProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZJAddressPickerView : UIView

/// 配置数据
@property (nonatomic, strong) ZJAddressConfig *addressConfig;
/// 数据源
@property (nonatomic, strong, readonly) ZJAreaProvider *areaProvider;
/// 选择完成后回传的数据。请注意，有的区域可能没有那么多层级。
/// 比如你设置了4级联动，但是有的省市区只有三级，此时取值需要注意。
/// 为了避免数组越界问题，当数据没有那么多层级时，回传的数据以无实际数据的空对象[ZJAreaData empty]返回
@property (nonatomic, copy) ZJAddressPickerViewCompletion completion;

/// 显示
- (void)show;
/// 移除
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
