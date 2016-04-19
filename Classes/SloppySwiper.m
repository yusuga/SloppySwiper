//
//  SloppySwiper.m
//
//  Created by Arkadiusz Holko http://holko.pl on 29-05-14.
//

#import "SloppySwiper.h"
#import "SSWAnimator.h"
#import "SSWDirectionalPanGestureRecognizer.h"
#import "SloppySwiperViewControllerProtocol.h"
#import <LTNavigationBar/UINavigationBar+Awesome.h>
#import <UIColor-CrossFade/UIColor+CrossFade.h>

static NSString * const SloppySwiperUpdateNavigationBarAppearanceNotification = @"SloppySwiperUpdateNavigationBarAppearanceNotification";

@interface SloppySwiper() <UIGestureRecognizerDelegate>
@property (weak, readwrite, nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (weak, nonatomic) IBOutlet UINavigationController *navigationController;
@property (strong, nonatomic) SSWAnimator *animator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition *interactionController;
/// A Boolean value that indicates whether the navigation controller is currently animating a push/pop operation.
@property (nonatomic) BOOL duringAnimation;

@property (weak, nonatomic) UIViewController *fromViewController;
@property (weak, nonatomic) UIViewController *toViewController;
@end

@implementation SloppySwiper

#pragma mark - Lifecycle

- (void)dealloc
{
    [_panRecognizer removeTarget:self action:@selector(pan:)];
    [_navigationController.view removeGestureRecognizer:_panRecognizer];
    [self unregisterForNotifications];
}

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
{
    NSCParameterAssert(!!navigationController);

    self = [super init];
    if (self) {
        _navigationController = navigationController;
        [self commonInit];
    }

    return self;
}

- (void)awakeFromNib
{
    [self commonInit];
}

- (void)commonInit
{
    SSWDirectionalPanGestureRecognizer *panRecognizer = [[SSWDirectionalPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    panRecognizer.direction = SSWPanDirectionRight;
    panRecognizer.maximumNumberOfTouches = 1;
    panRecognizer.delegate = self;
    [_navigationController.view addGestureRecognizer:panRecognizer];
    _panRecognizer = panRecognizer;

    _animator = [[SSWAnimator alloc] init];
    
    [self registerForNotifications];
}

#pragma mark - UIPanGestureRecognizer

- (void)pan:(UIPanGestureRecognizer*)recognizer
{
    UIView *view = self.navigationController.view;
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            if (self.navigationController.viewControllers.count > 1 && !self.duringAnimation) {
                self.interactionController = [[UIPercentDrivenInteractiveTransition alloc] init];
                self.interactionController.completionCurve = UIViewAnimationCurveEaseOut;
                
                [self.navigationController popViewControllerAnimated:YES];
            }
            break;
        case UIGestureRecognizerStateChanged:
        {
            [self updateNavigationBarAppearanceWithRatio:self.interactionController.percentComplete];
            
            CGPoint translation = [recognizer translationInView:view];
            // Cumulative translation.x can be less than zero because user can pan slightly to the right and then back to the left.
            CGFloat d = translation.x > 0 ? translation.x / CGRectGetWidth(view.bounds) : 0;
            [self.interactionController updateInteractiveTransition:d];
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
                case UIGestureRecognizerStateEnded:
            if (recognizer.state == UIGestureRecognizerStateEnded && [recognizer velocityInView:view].x > 0) {
                [self updateNavigationBarAppearanceWithRatio:1.];
                [self.interactionController finishInteractiveTransition];
            } else {
                [self updateNavigationBarAppearanceWithRatio:0.];
                [self.interactionController cancelInteractiveTransition];
                // When the transition is cancelled, `navigationController:didShowViewController:animated:` isn't called, so we have to maintain `duringAnimation`'s state here too.
                self.duringAnimation = NO;
            }
            self.interactionController = nil;
            break;
        default:
        case UIGestureRecognizerStatePossible:
            break;
    }
    
#if DEBUG
    NSString *stateStr;
    switch (recognizer.state) {
        case UIGestureRecognizerStateCancelled:
            stateStr = @"UIGestureRecognizerStateCancelled";
            break;
        case UIGestureRecognizerStateFailed:
            stateStr = @"UIGestureRecognizerStateFailed";
        case UIGestureRecognizerStatePossible:
            stateStr = @"UIGestureRecognizerStatePossible";
            break;
        default:
            break;
    }
    if (stateStr) {
        NSLog(@"%s; %@", __func__, stateStr);
    }
#endif
}

#pragma mark - UIGestureRecognizerDelegate

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.navigationController.viewControllers.count > 1) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UISlider class]]) {
        return NO;
    }
    return YES;
}

#pragma mark - UINavigationControllerDelegate

/**
 *  Launch
 *  1. will: FirstVC
 *  2. did: FirstVC
 *
 ******
 *
 *  Push
 *  1. from: FirstVC, to: SecondVC
 *  2. will: SecondVC
 *  3. did: SecondVC
 *
 *  Pop
 *  1. from: SecondVC, to: FirstVC
 *  2. interaction
 *  3. will: FirstVC
 *  4. did: FirstVC
 *
 ******
 *
 *  Pan - Finish
 *  1. from: SecondVC, to: FirstVC
 *  2. interaction
 *  3. will: FirstVC
 *  4. pan Began
 *  5. pan Changed
 *  6. pan Ended - Finish
 *  7. did: FirstVC
 *
 *  Pan - Cancel
 *  1. from: SecondVC, to: FirstVC
 *  2. interaction
 *  3. will: FirstVC
 *  4. pan Began
 *  5. pan Changed
 *  6. pan Ended - Cancel
 */

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    self.fromViewController = fromVC;
    self.toViewController = toVC;
    
    if (operation == UINavigationControllerOperationPop) {
        return self.animator;
    }
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    return self.interactionController;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (animated) {
        self.duringAnimation = YES;
    }
    
    if (self.fromViewController && self.toViewController) {
        if (self.interactionController) {
            [self updateNavigationBarAppearanceWithRatio:viewController == self.toViewController ? 0. : 1.];
        } else {
            [self updateNavigationBarAppearanceWithRatio:1.];
        }
    } else {
        // Displayed for the first time.
        [self updateNavigationBarAppearanceWithViewController:viewController];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    self.duringAnimation = NO;
    
    if (navigationController.viewControllers.count <= 1) {
        self.panRecognizer.enabled = NO;
    }
    else {
        self.panRecognizer.enabled = YES;
    }
    
    if (self.toViewController) {
        [self updateNavigationBarAppearanceWithRatio:viewController == self.toViewController ? 1. : 0.];
    }
}

#pragma mark - UINavigationBar

- (void)updateNavigationBarAppearanceWithRatio:(CGFloat)ratio
{
    UIBarStyle barStyle = ratio < 0.5 ? [self navigationBarStyleFromViewController:self.fromViewController] : [self navigationBarStyleFromViewController:self.toViewController];
    [self setNavigationBarStyle:barStyle];
    
    UIColor *fromBarColor = [self navigationBarColorFromViewController:self.fromViewController];
    UIColor *fromBarItemColor = [self navigationBarItemColorFromViewController:self.fromViewController];
    UIColor *toBarColor = [self navigationBarColorFromViewController:self.toViewController];
    UIColor *toBarItemColor = [self navigationBarItemColorFromViewController:self.toViewController];
    
    if (fromBarColor && toBarColor) {
        [self setNavigationBarColor:[UIColor colorForFadeBetweenFirstColor:fromBarColor
                                                     secondColor:toBarColor
                                                         atRatio:ratio]];
    }
    if (fromBarItemColor && toBarItemColor) {
        [self setNavigationBarItemColor:[UIColor colorForFadeBetweenFirstColor:fromBarItemColor
                                                         secondColor:toBarItemColor
                                                             atRatio:ratio]];
        
    }
    
    if (ratio == 0. || ratio == 1.) {
        [self setNavigationBarShadowImage:[self navigationBarShadowImageFromViewController:ratio == 0. ? self.fromViewController : self.toViewController]];
    }
}

- (void)updateNavigationBarAppearanceWithViewController:(UIViewController *)viewController
{
    [self setNavigationBarStyle:[self navigationBarStyleFromViewController:viewController]];
    [self setNavigationBarColor:[self navigationBarColorFromViewController:viewController]];
    [self setNavigationBarItemColor:[self navigationBarItemColorFromViewController:viewController]];
    [self setNavigationBarShadowImage:[self navigationBarShadowImageFromViewController:viewController]];
}

- (void)setNavigationBarStyle:(UIBarStyle)barStyle
{
    self.navigationController.navigationBar.barStyle = barStyle;
}

- (void)setNavigationBarColor:(UIColor *)color
{
    UINavigationBar *bar = self.navigationController.navigationBar;
    if (color) {
        [bar lt_setBackgroundColor:color];
    } else {
        [bar lt_reset];
    }
}

- (void)setNavigationBarItemColor:(UIColor *)color
{
    UINavigationBar *bar = self.navigationController.navigationBar;
    bar.tintColor = color;
    
    NSMutableDictionary *attr = [NSMutableDictionary dictionaryWithDictionary:bar.titleTextAttributes];
    if (color) {
        [attr setObject:color forKey:NSForegroundColorAttributeName];
    } else {
        [attr removeObjectForKey:NSForegroundColorAttributeName];
    }
    bar.titleTextAttributes = attr.count ? [attr copy] : nil;
}

- (void)setNavigationBarShadowImage:(UIImage *)image;
{
    self.navigationController.navigationBar.shadowImage = image;
}

#pragma mark - UINavigationBar - Private

- (UIBarStyle)navigationBarStyleFromViewController:(UIViewController *)viewCotnroller
{
    if ([viewCotnroller respondsToSelector:@selector(ssw_navigationBarStyle)]) {
        return [(id<SloppySwiperViewControllerProtocol>)viewCotnroller ssw_navigationBarStyle];
    }
    return self.navigationController.navigationBar.barStyle;
}

- (UIColor *)navigationBarColorFromViewController:(UIViewController *)viewController
{
    if ([viewController respondsToSelector:@selector(ssw_navigationBarColor)]) {
        return [viewController performSelector:@selector(ssw_navigationBarColor)];
    }
    return nil;
}

- (UIColor *)navigationBarItemColorFromViewController:(UIViewController *)viewController
{
    if ([viewController respondsToSelector:@selector(ssw_navigationBarItemColor)]) {
        return [viewController performSelector:@selector(ssw_navigationBarItemColor)];
    }
    return nil;
}

- (UIImage *)navigationBarShadowImageFromViewController:(UIViewController *)viewController
{
    if ([viewController respondsToSelector:@selector(ssw_navigationBarShadowImage)]) {
        return [viewController performSelector:@selector(ssw_navigationBarShadowImage)];
    }
    return self.navigationController.navigationBar.shadowImage;
}

#pragma mark - Notification

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateNavigationBarAppearance)
                                                 name:SloppySwiperUpdateNavigationBarAppearanceNotification
                                               object:nil];
}

- (void)unregisterForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SloppySwiperUpdateNavigationBarAppearanceNotification
                                                  object:nil];
}

+ (void)updateNavigationBarAppearance
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SloppySwiperUpdateNavigationBarAppearanceNotification
                                                        object:nil
                                                      userInfo:nil];
}

- (void)updateNavigationBarAppearance
{
    [self updateNavigationBarAppearanceWithViewController:self.navigationController.topViewController];
}

@end
