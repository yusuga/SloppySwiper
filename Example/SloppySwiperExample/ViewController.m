//
//  ViewController.m
//  SloppySwiperExample
//
//  Created by Arkadiusz on 29-05-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import "ViewController.h"
#import <SloppySwiper/SloppySwiperViewControllerProtocol.h>

@interface ViewController () <SloppySwiperViewControllerProtocol>

@property (nonatomic) UIColor *ssw_barColor;
@property (nonatomic) UIColor *ssw_barItemColor;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    NSUInteger stackCount = [self.navigationController.viewControllers count];

    if (stackCount % 2 == 0) {
        self.view.backgroundColor = [UIColor colorWithRed:0.921f green:0.929f blue:1.000f alpha:1.000f];
//        self.view.tintColor = [UIColor redColor];
        self.ssw_barColor = [UIColor blueColor];
        self.ssw_barItemColor = [UIColor whiteColor];
    } else {
        self.ssw_barColor = [UIColor greenColor];
        self.ssw_barItemColor = [UIColor blackColor];
//        self.view.tintColor = [UIColor greenColor];
    }

    self.title = [@(stackCount) stringValue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
