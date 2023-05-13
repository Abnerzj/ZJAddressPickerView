//
//  ZJAreaProvider.m
//  ZJAddressPickerViewDemo
//
//  Created by ZhangJun on 2023/5/12.
//

#import "ZJAreaProvider.h"

@implementation ZJAreaData

+ (instancetype)empty {
    ZJAreaData *data = [ZJAreaData new];
    data.id = @"";
    data.parentid = @"";
    data.name = @"";
    return data;
}

+ (instancetype)areaDataWithDict:(NSDictionary *)dict {
    ZJAreaData *areaData = [[ZJAreaData alloc] init];
    areaData.id = dict[@"id"];
    areaData.parentid = dict[@"parentid"];
    areaData.name = dict[@"name"];
    return areaData;
}

@end

@implementation ZJAddressConfig

- (instancetype)init {
    if (self = [super init]) {
        _maxLevels = 4;
        _title = @"请选择地址";
        _cancel = @"取消";
        _themColor = UIColor.blackColor;
        _textColor = UIColor.blackColor;
        _selectTextColor = [UIColor colorWithRed:133.0/255 green: 92.0/255 blue: 92.0/255 alpha: 1];
        _isGradientLine = NO;
        _viewHeight = 400.0;
    }
    return self;
}

@end

@implementation ZJAreaProvider

- (instancetype)init {
    if (self = [super init]) {
        _sourceList = @[];
        _selectedSources = @[];
    }
    return self;
}

/// 获取数据
- (void)loadAreaDataAtAreaId:(NSString *)areaId completion:(ZJAddressPickerViewCompletion)completion {
    NSMutableArray<ZJAreaData *> *dataList = [NSMutableArray array];
    [self.sourceList enumerateObjectsUsingBlock:^(ZJAreaData * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([areaId isEqualToString:item.parentid]) {
            [dataList addObject:item];
        }
    }];
    
    if (completion) {
        completion(dataList);
    }
}

- (NSArray<ZJAreaData *> *)sourceList {
    if (_sourceList.count == 0) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"adress" ofType:@"txt"];
        NSError *error = nil;
        NSString *encodingPath = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        if (!error && encodingPath.length) {
            NSData *resData = [encodingPath dataUsingEncoding:NSUTF8StringEncoding];
            if (resData.length) {
                NSArray<NSDictionary *> *areasDicts = [NSJSONSerialization JSONObjectWithData:resData options:kNilOptions error:&error];
                if (!error && areasDicts.count) {
                    NSMutableArray<ZJAreaData *> *areas = [NSMutableArray arrayWithCapacity:areasDicts.count];
                    [areasDicts enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull areasDict, NSUInteger idx, BOOL * _Nonnull stop) {
                        [areas addObject:[ZJAreaData areaDataWithDict:areasDict]];
                    }];
                    _sourceList = areas.copy;
                } else {
                    NSLog(@"发生错误 = %@", error);
                }
            }
        } else {
            NSLog(@"发生错误 = %@", error);
        }
    }
    return _sourceList;
}

@end
