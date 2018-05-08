//
//  ViewController.m
//  YKSDNDemo
//
//  Created by shuqiong on 2018/5/8.
//  Copyright © 2018年 shuqiong. All rights reserved.
//

#import "ViewController.h"
#import "YKSDNManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)getOptimalServer:(id)sender {
    
    [[YKSDNManager sharedManager] getOptimalServer:^(NSDictionary *serverInfo) {
        NSLog(@"optimalServer: %@", serverInfo);
    }];
    
}

@end
