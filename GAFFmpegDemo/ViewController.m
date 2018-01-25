//
//  ViewController.m
//  GAFFmpegDemo
//
//  Created by XDS on 2018/1/25.
//  Copyright © 2018年 MountainX. All rights reserved.
//

#import "ViewController.h"
#import "GACodec.h"
#import "CodeDecoder.h"

@interface ViewController ()
{
    CodeDecoder   *coDec;
    UIImageView  *imageV;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//     GACodec  *codec1 = [[GACodec alloc] initWithVideo:@"/Users/xds/Desktop/曹高安项目/GAFFmpegDemo/GAFFmpegDemo/只发精品！买完整版加微信zgkwdj -Chinese homemade vid.mp4"];
    coDec = [[CodeDecoder alloc] init];
    [coDec openWithPath:[[NSBundle  mainBundle] pathForResource:@"11" ofType:@"MP4"]];
    
    [coDec decodecFrame];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
