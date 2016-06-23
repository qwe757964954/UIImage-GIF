//
//  UIImage+YBFGIF.h
//  YiBiFen_CN
//
//  Created by 建星 on 16/4/8.
//  Copyright © 2016年 hhly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (YBFGIF)
/**
 *  gif动画
 *
 *  @param name     gif名字
 *  @param duration 动画时间
 *
 *  @return UIImage
 */
+ (UIImage *)sd_animatedGIFNamed:(NSString *)name withDuration:(float)duration;
+ (UIImage *)sd_animatedGIFWithData:(NSData *)data withDuration:(float)duration;

- (UIImage *)sd_animatedImageByScalingAndCroppingToSize:(CGSize)size;
/**
 *  imgView执行动画+图片集+重复次数
 *
 *  @param imgView 图片
 *  @param array   图片集
 *  @param count   重复次
 */
+(void)jx_animated:(UIImageView *)imgView withArrayObject:(NSMutableArray *)array andRepeatCount:(NSInteger)count;

/**
 *  高斯模糊
 *
 *  @param radius 模糊值
 *
 *  @return UIImage
 */
- (UIImage *)jx_stackBlur:(NSUInteger)radius;
/**
 *  获取屏幕图像
 *
 *  @param theView 来自哪个view
 *
 *  @return UIImage
 */
+ (UIImage *)imageFromView: (UIView *) theView;
/**
 *  获取屏幕范围内的图像
 *
 *  @param theView 想截取的view
 *  @param rect    rect
 *
 *  @return UIImage
 */
+ (UIImage *)imageFromView: (UIView *) theView   atFrame:(CGRect)rect;
@end
