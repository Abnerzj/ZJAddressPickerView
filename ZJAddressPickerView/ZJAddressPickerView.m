//
//  ZJAddressPickerView.m
//  ZJAddressPickerViewDemo
//
//  Created by Abnerzj on 2023/5/12.
//

#import "ZJAddressPickerView.h"

#define screen_width UIScreen.mainScreen.bounds.size.width
#define screen_height UIScreen.mainScreen.bounds.size.height

// 当前window
UIWindow * zj_keyWindow(void) {
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    if (@available(iOS 14.0, *)) {
        NSDictionary *infoDic = NSBundle.mainBundle.infoDictionary[@"UIApplicationSceneManifest"];
        // 通过infoDic,判断是否使用UIScene
        if (infoDic) {
            // 通过supportsMultipleScenes,判断是否支持多个场景
            if (UIApplication.sharedApplication.supportsMultipleScenes) {
                // 获取所有已链接Scenes
                NSSet <UIScene *> *connectedScenes = [UIApplication sharedApplication].connectedScenes;
                for (UIScene *scene in connectedScenes.allObjects) {
                    UISceneActivationState activationState = scene.activationState;
                    // 通过activationState,获取当前场景window对象
                    if (activationState == UISceneActivationStateForegroundActive) {
                        window =  ((id<UIWindowSceneDelegate>)scene.delegate).window;
                    }
                }
            } else {
                window = ((id<UIWindowSceneDelegate>)[UIApplication sharedApplication].connectedScenes.anyObject.delegate).window;
            }
        }
    } else if (@available(iOS 13.0, *)) {
        for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                window = windowScene.windows.firstObject;
                break;
            }
        }
    }
    return window ? window : [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

@interface UIView (ZJAddressPickerView)

@end

@implementation UIView (ZJAddressPickerView)

/// 设置某几个角的圆角
- (void)setCorner:(UIRectCorner)corners radii:(CGFloat)radii {
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(radii, radii)];
    CAShapeLayer *maskLayer = [CAShapeLayer new];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
}

/// 设置渐变颜色
- (void)setGradientColor:(NSArray *)colors startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint corner:(CGFloat)corner {
    [self removeAllSublayers];
    CAGradientLayer *gradientLayer = [CAGradientLayer new];
    gradientLayer.cornerRadius = corner;
    gradientLayer.frame = self.bounds;
    // 设置渐变的主颜色(可多个颜色添加)
    gradientLayer.colors = colors;
    // startPoint与endPoint分别为渐变的起始方向与结束方向, 它是以矩形的四个角为基础的,默认是值是(0.5,0)和(0.5,1)
    // (0,0)为左上角 (1,0)为右上角 (0,1)为左下角 (1,1)为右下角
    gradientLayer.startPoint = startPoint;
    gradientLayer.endPoint = endPoint;
    // 将gradientLayer作为子layer添加到主layer上
    [self.layer insertSublayer:gradientLayer atIndex:0];
}

/// 移除渐变
- (void)removeAllSublayers {
    if (self.layer.sublayers.count) {
        [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    }
}

@end

@interface ZJAddressPickerView ()<UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>

//省、市/区、县、镇、村（由maxLevels确定具体数据）
@property (nonatomic, strong) NSMutableArray<NSArray<ZJAreaData *> *> *addressList;
//标题数组
@property (nonatomic, strong) NSMutableArray<NSString *> *titleList;
//选择结果数组
@property (nonatomic, strong) NSMutableArray<ZJAreaData *> *result;
//按钮数组
@property (nonatomic, strong) NSMutableArray<UIButton *> *buttonList;
//数据列表数组
@property (nonatomic, strong) NSMutableArray<UITableView *> *tableViewList;
//判断是滚动还是点击
@property (nonatomic, assign) BOOL isClick;

@property (nonatomic, strong) UIView *containView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIView *sepLineView;
@property (nonatomic, strong) UIScrollView *titleScrollView;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIScrollView *contentScrollView;

@end

@implementation ZJAddressPickerView

- (UIView *)containView {
    if (!_containView) {
        _containView = [[UIView alloc] initWithFrame:CGRectMake(0, screen_height, screen_width, self.addressConfig.viewHeight)];
        _containView.backgroundColor = UIColor.whiteColor;
        [_containView setCorner:UIRectCornerTopLeft | UIRectCornerTopRight radii:8.0];
    }
    return _containView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, 160, 52)];
        _titleLabel.text = @"请选择地址";
        _titleLabel.textColor = self.addressConfig.textColor;
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelBtn.frame = CGRectMake(screen_width - 44 - 16, 0, 44, 52);
        [_cancelBtn setTitle:self.addressConfig.cancel forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:self.addressConfig.textColor forState:UIControlStateNormal];
        [_cancelBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_cancelBtn addTarget:self action:@selector(cancelBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (UIView *)sepLineView {
    if (!_sepLineView) {
        _sepLineView = [[UIView alloc] initWithFrame:CGRectMake(16, 52, screen_width - 32, 1)];
        _sepLineView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.12];
    }
    return _sepLineView;
}

- (UIScrollView *)titleScrollView {
    if (!_titleScrollView) {
        _titleScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 53, screen_width, 44)];
        _titleScrollView.showsHorizontalScrollIndicator = NO;
    }
    return _titleScrollView;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] initWithFrame:CGRectZero];
        _lineView.backgroundColor = self.addressConfig.textColor;
    }
    return _lineView;
}

- (UIScrollView *)contentScrollView {
    if (!_contentScrollView) {
        _contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.titleScrollView.frame), screen_width, self.addressConfig.viewHeight - CGRectGetMaxY(self.titleScrollView.frame))];
        _contentScrollView.delegate = self;
        _contentScrollView.pagingEnabled = YES;
        _contentScrollView.bounces = NO;
        _contentScrollView.showsHorizontalScrollIndicator = NO;
    }
    return _contentScrollView;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if ([super initWithCoder:coder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    _addressConfig = [ZJAddressConfig new];
    _areaProvider = [ZJAreaProvider new];
    _addressList = [NSMutableArray array];
    _titleList = [NSMutableArray array];
    _result = [NSMutableArray array];
    _buttonList = [NSMutableArray array];
    _tableViewList = [NSMutableArray array];
    [_titleList addObject:@"请选择"];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    CGPoint currentPoint = [touches.anyObject locationInView:self];
    if (!CGRectContainsPoint(self.containView.frame, currentPoint)) {
        [self dismiss];
    }
}

- (void)setupUI {
    self.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.6];
    self.frame = CGRectMake(0, 0, screen_width, screen_height);
    [zj_keyWindow() addSubview:self];
    [self addSubview:self.containView];
    [self.containView addSubview:self.titleLabel];
    [self.containView addSubview:self.cancelBtn];
    [self.containView addSubview:self.sepLineView];
    [self.containView addSubview:self.titleScrollView];
    [self.containView addSubview:self.contentScrollView];
}

- (void)setupSelectedSources {
    if (self.areaProvider.selectedSources.count == self.addressConfig.maxLevels && self.addressList.count) {
        __weak typeof(self) ws = self;
        [self.areaProvider.selectedSources enumerateObjectsUsingBlock:^(NSString * _Nonnull title, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong typeof(self) self = ws;
            if (idx < self.addressList.count) {
                NSArray<ZJAreaData *> *list = self.addressList[idx];
                [list enumerateObjectsUsingBlock:^(ZJAreaData * _Nonnull obj, NSUInteger idx2, BOOL * _Nonnull stop2) {
                    if ([obj.name isEqualToString:title]) {
                        [self disposeAreaDataLogic:obj tag:idx isModify:YES];
                        *stop2 = YES;
                    }
                }];
            }
        }];
    }
}

- (void)setupAllTitle:(NSUInteger)index {
    [self.titleScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.buttonList removeAllObjects];
    __block CGFloat x = 16;
    __weak typeof(self) ws = self;
    [self.titleList enumerateObjectsUsingBlock:^(NSString * _Nonnull title, NSUInteger i, BOOL * _Nonnull stop) {
        __strong typeof(self) self = ws;
        UIFont *font = [UIFont systemFontOfSize:14];
        CGFloat titleLenth = [self labelWithText:title font:font];
        UIButton *titleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        titleBtn.tag = i;
        [titleBtn setTitle:title forState:UIControlStateNormal];
        [titleBtn setTitleColor:self.addressConfig.textColor forState:UIControlStateNormal];
        [titleBtn setTitleColor:self.addressConfig.selectTextColor forState:UIControlStateSelected];
        titleBtn.selected = NO;
        titleBtn.titleLabel.font = font;
        titleBtn.frame = CGRectMake(x, 2, titleLenth, 40);
        x += (titleLenth + 6);
        [titleBtn addTarget:self action:@selector(titleBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.buttonList addObject:titleBtn];
        // 选中
        if (i == index) {
            [self titleBtnClicked:titleBtn];
        }
        [self.titleScrollView addSubview:titleBtn];
        self.titleScrollView.contentSize = CGSizeMake(x, 0);
    }];
    self.contentScrollView.contentSize = CGSizeMake(self.titleList.count * screen_width, 0);
}

- (void)setupOneTableView:(NSUInteger)btnTag {
    UITableView *tableView = nil;
    if (btnTag < self.tableViewList.count) {
        tableView = self.tableViewList[btnTag];
    } else {
        tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tableView.frame = CGRectMake(btnTag * screen_width, 0, screen_width, self.contentScrollView.frame.size.height);
        tableView.tag = btnTag;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = UIColor.clearColor;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.contentScrollView addSubview:tableView];
        if (self.tableViewList.count == 0) {
            [self.tableViewList addObject:tableView];
            [self getAreaData:0 code:nil completion:nil];
        } else {
            [self.tableViewList addObject:tableView];
        }
    }
}

#pragma mark - Function
- (void)cancelBtnClicked:(UIButton *)btn {
    [self dismiss];
}

- (void)titleBtnClicked:(UIButton *)btn {
    [self.buttonList enumerateObjectsUsingBlock:^(UIButton * _Nonnull tempBtn, NSUInteger idx, BOOL * _Nonnull stop) {
        tempBtn.selected = NO;
    }];
    btn.selected = YES;
    self.isClick = YES;
    [self setupOneTableView:btn.tag];
    [UIView animateWithDuration:0.25 animations:^{
        self.lineView.frame = CGRectMake(CGRectGetMinX(btn.frame) + btn.frame.size.width * 0.25, btn.frame.size.height - 3, btn.frame.size.width * 0.5, 3);
    }];
    
    if (self.addressConfig.isGradientLine) {
        self.lineView.backgroundColor = UIColor.clearColor;
        [self.lineView setGradientColor:@[(id)self.addressConfig.themColor.CGColor, (id)[self.addressConfig.themColor colorWithAlphaComponent:0.2].CGColor] startPoint:CGPointMake(0, 0.5) endPoint:CGPointMake(1.0, 0.5) corner:2];
    }
    [self.titleScrollView addSubview:self.lineView];
    self.contentScrollView.contentOffset = CGPointMake(btn.tag * screen_width, 0);
}

#pragma mark - 获取省市县街道
- (void)getAreaData:(NSUInteger)tag code:(NSString * _Nullable)code completion:(ZJAddressPickerViewCompletion)completion {
    if (!code) code = @"0";
    __weak typeof(self) ws = self;
    [self.areaProvider loadAreaDataAtAreaId:code completion:^(NSArray<ZJAreaData *> * _Nonnull list) {
        __strong typeof(self) self = ws;
        if (list.count) {
            if (tag < self.addressList.count) {
                self.addressList[tag] = list;
                if (tag != self.addressList.count - 1) {
                    [self.addressList removeObjectsInRange:NSMakeRange(tag + 1, self.addressList.count - 1 - tag)];
                }
            }else {
                [self.addressList addObject:list];
            }
            [self setupAllTitle:tag];
            [self.tableViewList[tag] reloadData];
        }
        if (completion) completion(list);
    }];
}

- (void)show {
    [self setupUI];
    [UIView animateWithDuration:0.25 animations:^{
        self.containView.frame = CGRectMake(0, screen_height - self.addressConfig.viewHeight, screen_width, self.addressConfig.viewHeight);
    }];
    [self setupAllTitle:0];
    [self setupSelectedSources];
}

- (void)dismiss {
    [UIView animateWithDuration:0.25 animations:^{
        self.containView.frame = CGRectMake(0, screen_height, screen_width, self.addressConfig.viewHeight);
    } completion:^(BOOL finished) {
        if (finished) {
            [self removeFromSuperview];
        }
    }];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.contentScrollView]) {
        CGFloat offset = scrollView.contentOffset.x / screen_width;
        NSInteger offsetIndex = (NSInteger)offset;
        if (offset != (CGFloat)offsetIndex) {
            self.isClick = NO;
        }
        if (!self.isClick) {
            if (offset == (CGFloat)offsetIndex) {
                UIButton *titleBtn = self.buttonList[offsetIndex];
                [self titleBtnClicked:titleBtn];
            }
        }
    }
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return tableView.tag < self.addressList.count ? self.addressList[tableView.tag].count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *addressCellIdentifier = @"ZJAddressPikerViewCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:addressCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addressCellIdentifier];
    }
    if (tableView.tag < self.addressList.count) {
        NSArray<ZJAreaData *> *list = self.addressList[tableView.tag];
        ZJAreaData *model = list[indexPath.row];
        ZJAreaData *selectedModel = tableView.tag < self.result.count ? self.result[tableView.tag] : nil;
        BOOL isSelected = [selectedModel.id isEqualToString:model.id];
        cell.textLabel.text = model.name;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.textColor = isSelected ? self.addressConfig.selectTextColor : UIColor.blackColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell ? cell : [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUInteger tag = tableView.tag;
    if (tag < self.addressList.count) {    
        NSArray<ZJAreaData *> *list = self.addressList[tag];
        ZJAreaData *model = list[indexPath.row];
        [self disposeAreaDataLogic:model tag:tag isModify:NO];
        [tableView reloadData];
    }
}

- (void)disposeAreaDataLogic:(ZJAreaData *)model tag:(NSUInteger)tag isModify:(BOOL)isModify {
    NSRange deleteRange = NSMakeRange(tag, self.result.count - tag);
    if (deleteRange.length > 0) {
        [self deleteData:self.titleList range:deleteRange];
        [self deleteData:self.buttonList range:deleteRange];
        [self deleteData:self.result range:deleteRange];
    }
    
    NSUInteger nextTag = tag + 1;
    self.titleList[tag] = [model.name isEqualToString:@""] ? @"请选择" : model.name;
    if (nextTag < self.addressConfig.maxLevels) {
        [self.titleList addObject:@"请选择"];
    }
    
    if (self.result.count > tag) {
        self.result[tag] = model;
    } else {
        [self.result addObject:model];
    }
    
    if (nextTag < self.addressConfig.maxLevels) {
        __weak typeof(self) ws = self;
        [self getAreaData:nextTag code:model.id completion:^(NSArray<ZJAreaData *> * _Nonnull list) {
            __strong typeof(self) self = ws;
            if (list.count == 0 && !isModify) {
                [self setupAllTitle:tag];
                [self dismiss];
                [self callbackData];
            }
        }];
    } else if (nextTag == self.addressConfig.maxLevels) {
        if (self.result.count < self.addressConfig.maxLevels) {
            NSLog(@"数据错误！请联系管理员");
            return;
        }
        [self setupAllTitle:tag];
        if (!isModify) {
            [self dismiss];
            [self callbackData];
        }
    }
}

- (void)callbackData {
    if (self.completion) {
        if (self.result.count < self.addressConfig.maxLevels) {
            for (NSUInteger i = self.result.count; i < self.addressConfig.maxLevels; i++) {
                [self.result addObject:[ZJAreaData empty]];
            }
        }
        self.completion(self.result);
    }
}

- (void)deleteData:(NSMutableArray *)array range:(NSRange)range {
    if (range.length > 0) {
        if (range.location < array.count && (range.location + range.length) <= array.count) {
            [array removeObjectsInRange:range];
        }
    }
}

/// 通过文字计算label的宽度（单行文字的情况）
- (CGFloat)labelWithText:(NSString *)text font:(UIFont *)font {
    CGRect rect = [text boundingRectWithSize:CGSizeMake(500000, 500000)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:@{NSFontAttributeName: font} context:nil];
    return rect.size.width;
}

- (void)dealloc {
    NSLog(@"%@ dealloc", NSStringFromClass(self.class));
}

@end
