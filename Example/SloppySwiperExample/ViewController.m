//
//  ViewController.m
//  SloppySwiperExample
//
//  Created by Arkadiusz on 29-05-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import "ViewController.h"
#import <SloppySwiper/SloppySwiper.h>
#import <SloppySwiper/SloppySwiperViewControllerProtocol.h>

@interface ViewController () <SloppySwiperViewControllerProtocol>

@property (nonatomic) UIBarStyle ssw_navigationBarStyle;
@property (nonatomic) UIColor *ssw_navigationBarColor;
@property (nonatomic) UIColor *ssw_navigationBarItemColor;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    NSUInteger stackCount = [self.navigationController.viewControllers count];

    if (stackCount % 2 == 0) {
        self.view.backgroundColor = [UIColor colorWithRed:0.921f green:0.929f blue:1.000f alpha:1.000f];
        self.ssw_navigationBarColor = [UIColor blueColor];
        self.ssw_navigationBarItemColor = [UIColor whiteColor];
    } else {
        self.ssw_navigationBarColor = [UIColor greenColor];
        self.ssw_navigationBarItemColor = [UIColor blackColor];
    }

    self.title = [@(stackCount) stringValue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)colorControlDidChange:(UISegmentedControl *)sender
{
    UIColor *barColor, *barItemColor;
    switch (sender.selectedSegmentIndex) {
        case 0:
            barColor = [UIColor redColor];
            barItemColor = [UIColor greenColor];
            break;
        case 1:
            barColor = [UIColor greenColor];
            barItemColor = [UIColor blueColor];
            break;
        case 2:
            barColor = [UIColor blueColor];
            barItemColor = [UIColor redColor];
            break;
        default:
            abort();
    }
    
    self.ssw_navigationBarColor = barColor;
    self.ssw_navigationBarItemColor = barItemColor;
    [SloppySwiper updateNavigationBarAppearance];
}

- (IBAction)styleControlDidChange:(UISegmentedControl *)sender
{
    NSParameterAssert(sender.selectedSegmentIndex == UIBarStyleDefault || sender.selectedSegmentIndex == UIBarStyleBlack);
    self.ssw_navigationBarStyle = sender.selectedSegmentIndex;
    [SloppySwiper updateNavigationBarAppearance];
}

@end
