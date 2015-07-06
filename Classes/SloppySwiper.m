//
//  SloppySwiper.m
//
//  Created by Arkadiusz Holko http://holko.pl on 29-05-14.
//

#import "SloppySwiper.h"
#import "SSWAnimator.h"
#import "SSWDirectionalPanGestureRecognizer.h"
#import <LTNavigationBar/UINavigationBar+Awesome.h>
#import <UIColor-CrossFade/UIColor+CrossFade.h>

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
            [self updateBarColorWithRatio:self.interactionController.percentComplete];
            
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
                [self updateBarColorWithRatio:1.];
                [self.interactionController finishInteractiveTransition];
            } else {
                [self updateBarColorWithRatio:0.];
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
            [self updateBarColorWithRatio:viewController == self.toViewController ? 0. : 1.];
        } else {
            [self updateBarColorWithRatio:1.];
        }
    } else {
        [self updateBarColor:viewController.view.tintColor];
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
    
    [self updateBarColorWithRatio:viewController == self.toViewController ? 1. : 0.];
}

#pragma mark - UINavigationBar

- (void)updateBarColorWithRatio:(CGFloat)ratio
{
    UIColor *fromBarColor = self.fromViewController.view.tintColor;
    UIColor *toBarColor = self.toViewController.view.tintColor;
    
    if (fromBarColor && toBarColor) {
        [self updateBarColor:[UIColor colorForFadeBetweenFirstColor:fromBarColor
                                                        secondColor:toBarColor
                                                            atRatio:ratio]];
    }
}

- (void)updateBarColor:(UIColor *)barColor
{
    if (!self.navigationBarColorChangingDisabled) {
        [self.navigationController.navigationBar lt_setBackgroundColor:barColor];
    }
}

@end
