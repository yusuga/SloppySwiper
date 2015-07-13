//
//  SloppySwiperViewControllerProtocol.h
//  Pods
//
//  Created by Yu Sugawara on 7/8/15.
//
//

#import <UIKit/UIKit.h>

@protocol SloppySwiperViewControllerProtocol <NSObject>

- (UIBarStyle)ssw_navigationBarStyle;
- (UIColor *)ssw_navigationBarColor;
- (UIColor *)ssw_navigationBarItemColor;

@optional
- (UIImage *)ssw_navigationBarShadowImage;

@end
