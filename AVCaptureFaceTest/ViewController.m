//
//  ViewController.m
//  OpenCVTest
//
//  Created by jackyshan on 2018/9/28.
//  Copyright © 2018年 GCI. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ShowController.h"

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, copy) NSMutableArray *facesViewArr;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

@property (nonatomic, strong) UIButton *button;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _facesViewArr = [NSMutableArray arrayWithCapacity:0];
    
    // 1.获取输入设备（摄像头）
    NSArray *devices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront].devices;
    AVCaptureDevice *deviceF = devices[0];
    
    // 2.根据输入设备创建输入对象
    AVCaptureDeviceInput*input = [[AVCaptureDeviceInput alloc] initWithDevice:deviceF error:nil];
    
    // 3.创建原数据的输出对象
    AVCaptureMetadataOutput *metaout = [[AVCaptureMetadataOutput alloc] init];
    
    // 4.设置代理监听输出对象输出的数据，在主线程中刷新
    [metaout setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // .设置代理监听输出对象输出的数据
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    self.session = [[AVCaptureSession alloc] init];
    
    // 5.设置输出质量(高像素输出)
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [self.session setSessionPreset:AVCaptureSessionPreset640x480];
    }

    // 6.添加输入和输出到会话
    [self.session beginConfiguration];
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
    }
    if ([self.session canAddOutput:metaout]) {
        [self.session addOutput:metaout];
    }
    [self.session commitConfiguration];
    
    // 7.告诉输出对象要输出什么样的数据, 识别人脸, 最多可识别10张人脸
    [metaout setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
    
    AVCaptureSession *session = (AVCaptureSession *)self.session;
    
    // 8.创建预览图层
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:_previewLayer atIndex:0];
    
    // 9.设置有效扫描区域(默认整个屏幕区域)（每个取值0~1, 以屏幕右上角为坐标原点）
    metaout.rectOfInterest = self.view.bounds;
    
    // 前置摄像头一定要设置一下 要不然画面是镜像
    for (AVCaptureVideoDataOutput* output in session.outputs) {
        for (AVCaptureConnection * av in output.connections) {
            // 判断是否是前置摄像头状态
            if (av.supportsVideoMirroring) {
                // 镜像设置
                av.videoOrientation = AVCaptureVideoOrientationPortrait;
                av.videoMirrored = YES;
            }
        }
    }
    
    // 10.开始扫描
    [self.session startRunning];
    
    // 下一步
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 40, 100, 30);
    [btn setTitle:@"下一步" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    [btn bringSubviewToFront:self.view];
}

- (void)next {
    if (!self.videoOutput.sampleBufferDelegate) {
        // 对实时视频帧进行相关的渲染操作, 指定代理
        [self.videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    }
}

// 当检测到了人脸会走这个回调
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    
    // 干掉旧画框
    for (UIView *faceView in self.facesViewArr) {
        [faceView removeFromSuperview];
    }
    [self.facesViewArr removeAllObjects];

    // 转换
    for (AVMetadataFaceObject *faceobject in metadataObjects) {
        AVMetadataObject *face = [self.previewLayer transformedMetadataObjectForMetadataObject:faceobject];
        CGRect r = face.bounds;
        // 画框
        UIView *faceBox = [[UIView alloc] initWithFrame:r];
        faceBox.layer.borderWidth = 3;
        faceBox.layer.borderColor = [UIColor redColor].CGColor;
        faceBox.backgroundColor = [UIColor clearColor];
        [self.view addSubview:faceBox];
        [self.facesViewArr addObject:faceBox];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
#pragma mark 从输出的数据流捕捉单一的图像帧
// AVCaptureVideoDataOutput获取实时图像，这个代理方法的回调频率很快，几乎与手机屏幕的刷新频率一样快
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
        
    if ([captureOutput isEqual:self.videoOutput]) {
        
        if ([self.session isRunning]) {
            [self.session stopRunning];
        }
    
       UIImage *img = [self imageFromSampleBuffer:sampleBuffer];
        
        // 识别完毕后将代理去掉，防止频繁调用代理方法而引起的“混乱”
        if (self.videoOutput.sampleBufferDelegate) {
            [self.videoOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
        }
    
        if (img) {
            ShowController *vc = [[ShowController alloc] init];
            vc.img = img;
            [self presentViewController:vc animated:YES completion:nil];
        }
    }
}

#pragma mark - Helper

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
       
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
       
    CIContext *context = [CIContext contextWithOptions:nil];//CPU
       
    CGRect rect = CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
       
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:rect];
       
    UIImage *image = [UIImage imageWithCGImage:cgImage];
       
    CGImageRelease(cgImage);
    
    return image;
}

@end
