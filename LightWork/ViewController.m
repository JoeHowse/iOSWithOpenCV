//
//  ViewController.m
//  LightWork
//
//  Created by Joseph Howse on 2015-12-09.
//  Copyright © 2015 Nummist Media Corporation Limited. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//  (1) Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//  (2) Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in the
//      documentation and/or other materials provided with the distribution.
//  (3) Neither the name of the copyright holder nor the names of its
//      contributors may be used to endorse or promote products derived from
//      this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
//  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
//  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <Photos/Photos.h>
#import <Social/Social.h>

#import <opencv2/core.hpp>
#import <opencv2/imgcodecs.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc.hpp>

#import "ViewController.h"
#import "VideoCamera.h"


enum BlendMode {
    None,
    Average,
    Multiply,
    Screen,
    HUD
};


@interface ViewController () <CvVideoCameraDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    cv::Mat originalStillMat;
    cv::Mat updatedStillMatGray;
    cv::Mat updatedStillMatRGBA;
    cv::Mat updatedVideoMatGray;
    cv::Mat updatedVideoMatRGBA;
    cv::Mat originalBlendSrcMat;
    cv::Mat convertedBlendSrcMat;
    
    BlendMode _blendMode;
}

@property IBOutlet UIImageView *imageView;
@property IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property IBOutlet UIToolbar *toolbar;

@property VideoCamera *videoCamera;
@property BOOL saveNextFrame;

@property BlendMode blendMode;
@property BOOL blendSettingsChanged;

- (IBAction)onTapToSetPointOfInterest:(UITapGestureRecognizer *)tapGesture;
- (IBAction)onColorModeSelected:(UISegmentedControl *)segmentedControl;
- (IBAction)onSwitchCameraButtonPressed;
- (IBAction)onSaveButtonPressed;
- (IBAction)onBlendSrcButtonPressed;
- (IBAction)onBlendModeButtonPressed:(UIBarButtonItem *)sender;

- (void)refresh;
- (void)processImage:(cv::Mat &)mat;
- (void)processImageHelper:(cv::Mat &)mat;
- (void)saveImage:(UIImage *)image;
- (void)showSaveImageFailureAlertWithMessage:(NSString *)message;
- (void)showSaveImageSuccessAlertWithImage:(UIImage *)image;
- (UIAlertAction *)shareImageActionWithTitle:(NSString *)title serviceType:(NSString *)serviceType image:(UIImage *)image;
- (void)startBusyMode;
- (void)stopBusyMode;
- (UIAlertAction *)blendModeActionWithTitle:(NSString *)title blendMode:(BlendMode)blendMode;
- (void)convertBlendSrcMatToWidth:(int)dstW height:(int)dstH;

@end


@implementation ViewController

- (BlendMode)blendMode {
    return _blendMode;
}

- (void)setBlendMode:(BlendMode)blendMode {
    if (blendMode != _blendMode) {
        _blendMode = blendMode;
        self.blendSettingsChanged = YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *originalStillImage = [UIImage imageNamed:@"Fleur.jpg"];
    UIImageToMat(originalStillImage, originalStillMat);
    
    self.videoCamera = [[VideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.letterboxPreview = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    
    [self refresh];
}

- (IBAction)onTapToSetPointOfInterest:(UITapGestureRecognizer *)tapGesture {
    if (tapGesture.state == UIGestureRecognizerStateEnded) {
        if (self.videoCamera.running) {
            CGPoint tapPoint = [tapGesture locationInView:self.imageView];
            [self.videoCamera setPointOfInterestInParentViewSpace:tapPoint];
        }
    }
}

- (IBAction)onColorModeSelected:(UISegmentedControl *)segmentedControl {
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            self.videoCamera.grayscaleMode = NO;
            break;
        default:
            self.videoCamera.grayscaleMode = YES;
            break;
    }
    [self refresh];
}

- (IBAction)onSwitchCameraButtonPressed {
    
    if (self.videoCamera.running) {
        switch (self.videoCamera.defaultAVCaptureDevicePosition) {
            case AVCaptureDevicePositionFront:
                self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
                [self refresh];
                break;
            default:
                [self.videoCamera stop];
                [self refresh];
                break;
        }
    }
    
    else {
        // Hide the still image.
        self.imageView.image = nil;
        
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        [self.videoCamera start];
    }
}

- (IBAction)onSaveButtonPressed {
    [self startBusyMode];
    if (self.videoCamera.running) {
        self.saveNextFrame = YES;
    } else {
        [self saveImage:self.imageView.image];
    }
}

- (void)refresh {
    
    if (self.videoCamera.running) {
        // Hide the still image.
        self.imageView.image = nil;
        
        // Restart the video.
        [self.videoCamera stop];
        [self.videoCamera start];
    }
    
    else {
        // Refresh the still image.
        UIImage *image;
        if (self.videoCamera.grayscaleMode) {
            cv::cvtColor(originalStillMat, updatedStillMatGray, cv::COLOR_RGBA2GRAY);
            [self processImage:updatedStillMatGray];
            image = MatToUIImage(updatedStillMatGray);
        } else {
            cv::cvtColor(originalStillMat, updatedStillMatRGBA, cv::COLOR_RGBA2BGRA);
            [self processImage:updatedStillMatRGBA];
            cv::cvtColor(updatedStillMatRGBA, updatedStillMatRGBA, cv::COLOR_BGRA2RGBA);
            image = MatToUIImage(updatedStillMatRGBA);
        }
        self.imageView.image = image;
    }
}

- (void)processImage:(cv::Mat &)mat {
    
    if (self.videoCamera.running) {
        switch (self.videoCamera.defaultAVCaptureVideoOrientation) {
            case AVCaptureVideoOrientationLandscapeLeft:
            case AVCaptureVideoOrientationLandscapeRight:
                // The landscape video is captured upside-down.
                // Rotate it by 180 degrees.
                cv::flip(mat, mat, -1);
                break;
            default:
                break;
        }
    }
    
    [self processImageHelper:mat];
    
    if (self.saveNextFrame) {
        // The video frame, 'mat', is not safe for long-running
        // operations such as saving to file. Thus, we copy its
        // data to another cv::Mat first.
        UIImage *image;
        if (self.videoCamera.grayscaleMode) {
            mat.copyTo(updatedVideoMatGray);
            image = MatToUIImage(updatedVideoMatGray);
        } else {
            cv::cvtColor(mat, updatedVideoMatRGBA, cv::COLOR_BGRA2RGBA);
            image = MatToUIImage(updatedVideoMatRGBA);
        }
        [self saveImage:image];
        self.saveNextFrame = NO;
    }
}

- (void)processImageHelper:(cv::Mat &)mat {
    
    if (originalBlendSrcMat.empty()) {
        // No blending source has been selected.
        // Do nothing.
        return;
    }
    
    if (convertedBlendSrcMat.rows != mat.rows || convertedBlendSrcMat.cols != mat.cols || convertedBlendSrcMat.type() != mat.type() || self.blendSettingsChanged) {
        
        // Resize the blending source and convert its format.
        [self convertBlendSrcMatToWidth:mat.cols height:mat.rows];
        
        // Apply any mode-dependent operations to the blending source.
        switch (self.blendMode) {
            case Screen:
                /* Pseudocode:
                 convertedBlendSrcMat = 255 – convertedBlendSrcMat;
                 */
                cv::subtract(255.0, convertedBlendSrcMat, convertedBlendSrcMat);
                break;
            case HUD:
                /* Pseudocode:
                 convertedBlendSrcMat = 255 – Laplacian(GaussianBlur(convertedBlendSrcMat));
                 */
                cv::GaussianBlur(convertedBlendSrcMat, convertedBlendSrcMat, cv::Size(5, 5), 0.0);
                cv::Laplacian(convertedBlendSrcMat, convertedBlendSrcMat, -1, 3);
                if (!self.videoCamera.grayscaleMode) {
                    // The background is in color.
                    // Give the foreground a yellowish green tint, which will stand out against most backgrounds.
                    cv::multiply(cv::Scalar(0.0, 1.0, 0.5), convertedBlendSrcMat, convertedBlendSrcMat);
                }
                cv::subtract(255.0, convertedBlendSrcMat, convertedBlendSrcMat);
                break;
            default:
                break;
        }
        
        self.blendSettingsChanged = NO;
    }
    
    // Combine the blending source and the current frame.
    switch (self.blendMode) {
        case Average:
            /* Pseudocode:
             mat = 0.5 * mat + 0.5 * convertedBlendSrcMat;
             */
            cv::addWeighted(mat, 0.5, convertedBlendSrcMat, 0.5, 0.0, mat);
            break;
        case Multiply:
            /* Pseudocode:
             mat = mat * convertedBlendSrcMat / 255;
             */
            cv::multiply(mat, convertedBlendSrcMat, mat, 1.0 / 255.0);
            break;
        case Screen:
        case HUD:
            /* Pseudocode:
             mat = 255 – (255 – mat) * convertedBlendSrcMat / 255;
             */
            cv::subtract(255.0, mat, mat);
            cv::multiply(mat, convertedBlendSrcMat, mat, 1.0 / 255.0);
            cv::subtract(255.0, mat, mat);
            break;
        default:
            break;
    }
}

- (void)saveImage:(UIImage *)image {
    
    // Try to save the image to a temporary file.
    NSString *outputPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.png"];
    if (![UIImagePNGRepresentation(image) writeToFile:outputPath atomically:YES]) {
        
        // Show an alert describing the failure.
        [self showSaveImageFailureAlertWithMessage:@"The image could not be saved to the temporary directory."];
        
        return;
    }
    
    // Try to add the image to the Photos library.
    NSURL *outputURL = [NSURL URLWithString:outputPath];
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    [photoLibrary performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:outputURL];
    } completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            // Show an alert describing the success, with sharing options.
            [self showSaveImageSuccessAlertWithImage:image];
        } else {
            // Show an alert describing the failure.
            [self showSaveImageFailureAlertWithMessage:error.localizedDescription];
        }
    }];
}

- (void)showSaveImageFailureAlertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed to save image" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self stopBusyMode];
    }];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showSaveImageSuccessAlertWithImage:(UIImage *)image {
    
    // Create a "Saved image" alert.
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Saved image" message:@"The image has been added to your Photos library. Would you like to share it with your friends?" preferredStyle:UIAlertControllerStyleAlert];
    
    // If the user has a Facebook account on this device, add a "Post on Facebook" button to the alert.
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        UIAlertAction *facebookAction = [self shareImageActionWithTitle:@"Post on Facebook" serviceType:SLServiceTypeFacebook image:image];
        [alert addAction:facebookAction];
    }
    
    // If the user has a Twitter account on this device, add a "Tweet" button to the alert.
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        UIAlertAction *twitterAction = [self shareImageActionWithTitle:@"Tweet" serviceType:SLServiceTypeTwitter image:image];
        [alert addAction:twitterAction];
    }
    
    // If the user has a Sina Weibo account on this device, add a "Post on Sina Weibo" button to the alert.
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]) {
        UIAlertAction *sinaWeiboAction = [self shareImageActionWithTitle:@"Post on Sina Weibo" serviceType:SLServiceTypeSinaWeibo image:image];
        [alert addAction:sinaWeiboAction];
    }
    
    // If the user has a Tencent Weibo account on this device, add a "Post on Tencent Weibo" button to the alert.
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTencentWeibo]) {
        UIAlertAction *tencentWeiboAction = [self shareImageActionWithTitle:@"Post on Tencent Weibo" serviceType:SLServiceTypeTencentWeibo image:image];
        [alert addAction:tencentWeiboAction];
    }
    
    // Add a "Do not share" button to the alert.
    UIAlertAction *doNotShareAction = [UIAlertAction actionWithTitle:@"Do not share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self stopBusyMode];
    }];
    [alert addAction:doNotShareAction];
    
    // Show the alert.
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIAlertAction *)shareImageActionWithTitle:(NSString *)title serviceType:(NSString *)serviceType image:(UIImage *)image {
    UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:serviceType];
        [composeViewController addImage:image];
        [self presentViewController:composeViewController animated:YES completion:^{
            [self stopBusyMode];
        }];
    }];
    return action;
}

- (void)startBusyMode {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView startAnimating];
        for (UIBarItem *item in self.toolbar.items) {
            item.enabled = NO;
        }
    });
}

- (void)stopBusyMode {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView stopAnimating];
        for (UIBarItem *item in self.toolbar.items) {
            item.enabled = YES;
        }
    });
}

- (IBAction)onBlendSrcButtonPressed {
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        // The Photos album is unavailable.
        // Show an error message.
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Photos album unavailable" message:@"Go to the Settings app and give LightWork permission to access your Photos album." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    
    // Pick from the Photos album.
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    // Pick from still images, not movies.
    picker.mediaTypes = [NSArray arrayWithObject:@"public.image"];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    UIImageToMat(image, originalBlendSrcMat);
    
    if (self.blendMode == None) {
        // Blending is currently deactivated.
        // Activate "Average" blending so that the user sees some result.
        self.blendMode = Average;
    }
    
    self.blendSettingsChanged = YES;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBlendModeButtonPressed:(UIBarButtonItem *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.barButtonItem = sender;
    
    UIAlertAction *averageAction = [self blendModeActionWithTitle:@"Average" blendMode:Average];
    [alert addAction:averageAction];
    
    UIAlertAction *multiplyAction = [self blendModeActionWithTitle:@"Multiply" blendMode:Multiply];
    [alert addAction:multiplyAction];
    
    UIAlertAction *screenAction = [self blendModeActionWithTitle:@"Screen" blendMode:Screen];
    [alert addAction:screenAction];
    
    UIAlertAction *hudAction = [self blendModeActionWithTitle:@"HUD" blendMode:HUD];
    [alert addAction:hudAction];
    
    UIAlertAction *noneAction = [self blendModeActionWithTitle:@"None" blendMode:None];
    [alert addAction:noneAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIAlertAction *)blendModeActionWithTitle:(NSString *)title blendMode:(BlendMode)blendMode {
    UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.blendMode = blendMode;
        if (!self.videoCamera.running) {
            [self refresh];
        }
    }];
    return action;
}

- (void)convertBlendSrcMatToWidth:(int)dstW height:(int)dstH {
    
    double dstAspectRatio = dstW / (double)dstH;
    
    int srcW = originalBlendSrcMat.cols;
    int srcH = originalBlendSrcMat.rows;
    double srcAspectRatio = srcW / (double)srcH;
    cv::Mat subMat;
    if (srcAspectRatio < dstAspectRatio) {
        int subMatH = (int)(srcW / dstAspectRatio);
        int startRow = (srcH - subMatH) / 2;
        int endRow = startRow + subMatH;
        subMat = originalBlendSrcMat.rowRange(startRow, endRow);
    } else {
        int subMatW = (int)(srcH * dstAspectRatio);
        int startCol = (srcW - subMatW) / 2;
        int endCol = startCol + subMatW;
        subMat = originalBlendSrcMat.colRange(startCol, endCol);
    }
    cv::resize(subMat, convertedBlendSrcMat, cv::Size(dstW, dstH), 0.0, 0.0, cv::INTER_LANCZOS4);
    
    int cvtColorCode;
    if (self.videoCamera.grayscaleMode) {
        cvtColorCode = cv::COLOR_RGBA2GRAY;
    } else {
        cvtColorCode = cv::COLOR_RGBA2BGRA;
    }
    cv::cvtColor(convertedBlendSrcMat, convertedBlendSrcMat, cvtColorCode);
}

@end
