//
//  ShowController.m
//  AVCaptureFaceTest
//
//  Created by G-Triumphant on 2023/2/28.
//  Copyright © 2023 GCI. All rights reserved.
//

#import "ShowController.h"

@interface ShowController ()

@end

@implementation ShowController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIImageView *imgView = [[UIImageView alloc] initWithImage:self.img];
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    imgView.bounds = self.view.bounds;
    [self.view addSubview:imgView];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
