//
//  ZWMSegmentView.m
//  ZWMSegmentController
//
//  Created by 伟明 on 2017/11/23.
//  Copyright © 2017年 伟明. All rights reserved.
//

#import "ZWMSegmentView.h"

typedef void(^ZWMIndexBlock)(NSUInteger ,UIButton *);
int const ZWMSegmentHeight = 28;//可根据项目需求设置高度
int const ZWMSegmentBgHeight = 42;//可根据项目需求设置高度

@interface ZWMSegmentView ()
@property (nonatomic, strong, readwrite) NSMutableArray *buttons;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong, readwrite) UIScrollView *contentView;
@property (nonatomic, assign) int segmentHeight;
@property (nonatomic, readwrite) NSUInteger index;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) UIButton *selectedButton; /**< 当前被选中的按钮*/
@property (nonatomic, strong) UIView *indicateView;     /**< 指示杆*/
@property (nonatomic, copy)   ZWMIndexBlock indexBlock;
@property (nonatomic, assign) CGFloat indicateHeight;   /**< 指示杆高度*/
@property (nonatomic, assign, readwrite) NSTimeInterval duration;  /**< 滑动时间*/
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign, readwrite) CGFloat buttonSpace;      /**< 按钮title到边的间距*/
@property (nonatomic, assign) CGFloat minItemSpace;     /**< 最小Item之间的间距*/
@property (nonatomic, strong) UIFont *normalFont;
@property (nonatomic, strong) UIFont *selectFont;

@end

@implementation ZWMSegmentView

+ (instancetype)segmentViewWithFrame:(CGRect)frame titles:(NSArray<NSString *> *)titles {
    return [[self alloc] initWithFrame:frame titles:titles];
}

- (instancetype)initWithFrame:(CGRect)frame titles:(NSArray <NSString *>*)titles {
    self = [super initWithFrame:frame];
    if (!titles.count || !self) {
        return nil;
    }
    
    _titles = titles;
    _size = frame.size;
    [self segmentBasicSetting];
    [self segmentPageSetting];
    
    return self;
}

- (void)segmentBasicSetting {
    self.backgroundColor = kClearColor;
    _buttons = [NSMutableArray array];
    _segmentHeight = ZWMSegmentHeight;
    _minItemSpace = 40.;
    _segmentTintColor = [UIColor blackColor];
    _segmentNormalColor = [UIColor blackColor];
    _normalFont = PingFangFont_Medium(16);
    _selectFont = PingFangFont_Bold(16);
    _indicateHeight = 0;
    _duration = 0.0;
    _scrollEnabled = YES;
    _showSeparateLine = NO;
//    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, _size.width, _segmentHeight);
}

- (CGFloat)calculateSpace {
    CGFloat space = 0;
    CGFloat totalWidth = 0;
    
    for (NSString *title in _titles) {
        CGSize titleSize = [title sizeWithAttributes:@{NSFontAttributeName : _normalFont}];
        totalWidth += titleSize.width;
    }
    
    space = (self.contentView.mj_w - totalWidth) / _titles.count / 2;
    if (space > _minItemSpace / 2) {
        return space;
    } else {
        return _minItemSpace / 2;
    }
}

- (void)segmentPageSetting {
    _backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    _backgroundImageView.clipsToBounds = YES;
    _backgroundImageView.backgroundColor = kClearColor;
    [self addSubview:_backgroundImageView];
    
    CGFloat bg_top = (ZWMSegmentBgHeight - _segmentHeight) / 2;
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(12, bg_top, _size.width - 24, _segmentHeight)];
    [self addSubview:bgView];
    _contentView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, bgView.mj_w, bgView.mj_h)];
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.showsHorizontalScrollIndicator = NO;
    _contentView.showsVerticalScrollIndicator = NO;
    _contentView.scrollEnabled = _scrollEnabled;
    _indicateView = [[UIView alloc] initWithFrame:CGRectMake(0, _contentView.mj_h - _indicateHeight, _contentView.mj_w, _indicateHeight)];
    _indicateView.backgroundColor = _segmentTintColor;
    _indicateView.layer.cornerRadius  = 1.5;
    _indicateView.layer.masksToBounds  = YES;
    CGFloat item_x = 0;
    CGFloat wid = _contentView.mj_w/5.0;
//    _buttonSpace = [self calculateSpace];
    CGFloat space = 8;
    for (int i = 0; i < _titles.count; i++) {
        NSString *title = _titles[i];
//        CGSize titleSize = [title sizeWithAttributes:@{NSFontAttributeName: _font}];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        //_buttonSpace * 2 +
        [button setTag:i];
        [button.titleLabel setFont:_normalFont];
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:_segmentNormalColor forState:UIControlStateNormal];
        [button setTitleColor:_segmentTintColor forState:UIControlStateSelected];
        [UIImage loadWithBlock2x:@"zx_segment_btn_normal" Image:^(UIImage * _Nonnull imageBlock) {
            [button setBackgroundImage:[imageBlock resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 14) resizingMode:UIImageResizingModeStretch] forState:(UIControlStateNormal)];
        }];
        [UIImage loadWithBlock2x:@"zx_segment_btn_select" Image:^(UIImage * _Nonnull imageBlock) {
            [button setBackgroundImage:[imageBlock resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 14) resizingMode:UIImageResizingModeStretch] forState:(UIControlStateSelected)];
        }];
        
        [button addTarget:self action:@selector(didClickButton:) forControlEvents:UIControlEventTouchUpInside];
        [button sizeToFit];
        wid = button.mj_w + 36;
        
        button.frame = CGRectMake(item_x, 0,  wid, _contentView.mj_h);

        [_contentView addSubview:button];
        
        [_buttons addObject:button];
        //_buttonSpace * 2 +
        
        item_x = item_x + wid + space;
        
        if (i == 0) {
            button.selected = YES;
            _selectedButton = button;
        }
    }
    self.contentView.contentSize = CGSizeMake(item_x, _segmentHeight);

    if (_buttons.count <= 3){
        CGFloat centerX = _contentView.l_width / (_buttons.count + 1);
        for (int i = 0; i < _buttons.count; i++) {
            UIButton *btn = _buttons[i];
            btn.l_centerX = centerX * (i+1);
        }
        self.contentView.contentSize = CGSizeMake(self.contentView.l_width, _segmentHeight);
    }

    _selectedButton.titleLabel.font = _selectFont;
    // 添加指示杆  wid
    if (_titles.count > 1) {
//         [_contentView addSubview:_indicateView];
//        WEAKSELF
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self scrollIndicateView];
//        });

    }
    
    
    [bgView addSubview:_contentView];
}

#pragma mark - 按钮点击

- (void)didClickButton:(UIButton *)button {
    if (button != _selectedButton) {
        
        button.titleLabel.font = PingFangFont_Bold(16);
        button.selected = YES;
        _selectedButton.titleLabel.font = PingFangFont_Medium(16);
        _selectedButton.selected = NO;
        _selectedButton = button;
        [self scrollSegementView];
    }
   
    if (_indexBlock) {
        _indexBlock(_selectedButton.tag, button);
    }
    [self scrollIndicateView];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    [self scrollIndicateView];
}

#pragma mark - 滑动
/**
 根据选中的按钮滑动指示杆
 */
- (void)scrollIndicateView {
}

/**
 根据选中调整segementView的offset
 */
- (void)scrollSegementView {
    CGFloat selectedWidth = _selectedButton.frame.size.width;
    CGFloat offsetX = (_contentView.mj_w - selectedWidth) / 2;
    
    if (_selectedButton.frame.origin.x <= _contentView.mj_w / 2) {
        [_contentView setContentOffset:CGPointMake(0, 0) animated:YES];
    } else if (CGRectGetMaxX(_selectedButton.frame) >= (_contentView.contentSize.width - _contentView.mj_w / 2)) {
        [_contentView setContentOffset:CGPointMake(_contentView.contentSize.width - _contentView.mj_w, 0) animated:YES];
    } else {
        [_contentView setContentOffset:CGPointMake(CGRectGetMinX(_selectedButton.frame) - offsetX, 0) animated:YES];
    }
}

- (void)adjustOffsetXToFixIndicatePosition:(CGFloat)offsetX {
}

#pragma mark - index

- (NSUInteger)index {
    return _selectedButton.tag;
}

- (void)setSelectedAtIndex:(NSUInteger)index {
    for (UIView *view in _contentView.subviews) {
        if ([view isKindOfClass:[UIButton class]] && view.tag == index) {
            UIButton *button = (UIButton *)view;
            [self didClickButton:button];
            break;
        }
    }
}

- (CGFloat)widthAtIndex:(NSUInteger)index {
    if (index > _titles.count - 1) {
        return 0;
    }
    UIButton *button = [_buttons objectAtIndex:index];
    return CGRectGetWidth(button.frame);
}

- (void)selectedAtIndex:(void (^)(NSUInteger, UIButton *))indexBlock {
    if (indexBlock) {
        _indexBlock = indexBlock;
    }
}

#pragma mark - set

- (void)setSeparateColor:(UIColor *)separateColor {
    _separateColor = separateColor;
    
}

- (void)setSegmentTintColor:(UIColor *)segmentTintColor {
    _segmentTintColor = segmentTintColor;
    _indicateView.backgroundColor = segmentTintColor;
    for (UIView *view in _contentView.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            [button setTitleColor:segmentTintColor
                         forState:UIControlStateSelected];
        }
    }
}

- (void)setSegmentNormalColor:(UIColor *)segmentNormalColor {
    _segmentNormalColor = segmentNormalColor;
    for (UIView *view in _contentView.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            //WHITE_BLACK_COLOR;  
            [button setTitleColor:segmentNormalColor
                         forState:UIControlStateNormal];
        }
    }
}

- (void)setStyle:(ZWMSegmentStyle)style {
    _style = style;
    
    if (style==ZWMSegmentStyleFlush) {
        _indicateView.mj_x = _selectedButton.mj_x;
        _indicateView.mj_w = [self widthAtIndex:0];
    }
}

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    _scrollEnabled = scrollEnabled;
    
    _contentView.scrollEnabled = scrollEnabled;
}

- (void)setShowSeparateLine:(BOOL)showSeparateLine {
    _showSeparateLine = showSeparateLine;
    
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImage = backgroundImage;
    
    if (backgroundImage) {
        self.backgroundImageView.image = backgroundImage;
        self.contentView.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark - get

- (int)segmentHeight {
    return _segmentHeight;
}

@end
