//
//  ZJAreaProvider.h
//  ZJAddressPickerViewDemo
//
//  Created by Abnerzj on 2023/5/12.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZJAreaData;

typedef void (^ZJAddressPickerViewCompletion)(NSArray<ZJAreaData *> *list);

/// 数据模型
@interface ZJAreaData : NSObject

@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSString *parentid;
@property (nonatomic, copy) NSString *name;

+ (instancetype)empty;
+ (instancetype)areaDataWithDict:(NSDictionary *)dict;

@end


/// 一些自定义配置
@interface ZJAddressConfig : NSObject

/// 可选级别（默认4级，可达5级，本地数据源只支持4级联动数据）
@property (nonatomic, assign) NSUInteger maxLevels;
/// 标题
@property (nonatomic, copy) NSString *title;
/// 取消按钮
@property (nonatomic, copy) NSString *cancel;
/// 主题色
@property (nonatomic, strong) UIColor *themColor;
/// 文本颜色
@property (nonatomic, strong) UIColor *textColor;
/// 选中结果文本颜色
@property (nonatomic, strong) UIColor *selectTextColor;
/// 设置是否线条渐变,跟themColor相关连
@property (nonatomic, assign) BOOL isGradientLine;
/// 弹窗高度
@property (nonatomic, assign) CGFloat viewHeight;

@end


@interface ZJAreaProvider : NSObject

/// 数据源，分本地和网络两个来源：用户可以先通过网络获取直接赋值，否则从本地获取。
/// 注意，本地数据源只支持4级联动数据。
@property (nonatomic, copy) NSArray<ZJAreaData *> *sourceList;
/// 已选择的数据，格式：@[@"广东省", @"深圳市", @"南山区", @"粤海街道"]
@property (nonatomic, copy) NSArray<NSString *> *selectedSources;

/// 获取数据
- (void)loadAreaDataAtAreaId:(NSString *)areaId completion:(ZJAddressPickerViewCompletion)completion;

@end

NS_ASSUME_NONNULL_END
