//
//  CaptureViewController.m
//  ManyMasks
//
//  Created by Joseph Howse on 2016-03-05.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
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

#import <opencv2/core.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc.hpp>

#import "CaptureViewController.h"
#import "FaceDetector.h"
#import "ReviewViewController.h"
#import "VideoCamera.h"

const double DETECT_RESIZE_FACTOR = 0.5;

@interface CaptureViewController () <CvVideoCameraDelegate> {
    FaceDetector *faceDetector;
    std::vector<Face> detectedFaces;
    Face bestDetectedFace;
    Face faceToMerge0;
    Face faceToMerge1;
}

@property IBOutlet UIView *backgroundView;

@property IBOutlet UIBarButtonItem *face0Button;
@property IBOutlet UIBarButtonItem *face1Button;
@property IBOutlet UIBarButtonItem *mergeButton;

@property IBOutlet UIImageView *face0ImageView;
@property IBOutlet UIImageView *face1ImageView;

@property VideoCamera *videoCamera;

- (IBAction)onTapToSetPointOfInterest:(UITapGestureRecognizer *)tapGesture;
- (IBAction)onColorModeSelected:(UISegmentedControl *)segmentedControl;
- (IBAction)onSwitchCameraButtonPressed;
- (IBAction)onFace0ButtonPressed;
- (IBAction)onFace1ButtonPressed;

- (void)refresh;
- (void)processImage:(cv::Mat &)mat;
- (void)showFace:(Face &)face inImageView:(UIImageView *)imageView;
- (UIImage *)imageFromCapturedMat:(const cv::Mat &)mat;

@end

@implementation CaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (faceDetector == NULL) {
        
        NSBundle *bundle = [NSBundle mainBundle];
        
        std::string humanFaceCascadePath = [[bundle pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"] UTF8String];
        std::string catFaceCascadePath = [[bundle pathForResource:@"haarcascade_frontalcatface_extended" ofType:@"xml"] UTF8String];
        std::string leftEyeCascadePath = [[bundle pathForResource:@"haarcascade_lefteye_2splits" ofType:@"xml"] UTF8String];
        std::string rightEyeCascadePath = [[bundle pathForResource:@"haarcascade_righteye_2splits" ofType:@"xml"] UTF8String];
        
        faceDetector = new FaceDetector(humanFaceCascadePath, catFaceCascadePath, leftEyeCascadePath, rightEyeCascadePath);
    }
    
    self.face0Button.enabled = NO;
    self.face1Button.enabled = NO;
    self.mergeButton.enabled = (!faceToMerge0.isEmpty() && !faceToMerge1.isEmpty());
    
    self.videoCamera = [[VideoCamera alloc] initWithParentView:self.backgroundView];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showReviewModally"]) {
        ReviewViewController *reviewViewController = segue.destinationViewController;
        Face mergedFace(faceToMerge0, faceToMerge1);
        reviewViewController.image = [self imageFromCapturedMat:mergedFace.getMat()];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    if (faceDetector != NULL) {
        delete faceDetector;
        faceDetector = NULL;
    }
}

- (void)dealloc {
    if (faceDetector != NULL) {
        delete faceDetector;
        faceDetector = NULL;
    }
}

- (IBAction)onTapToSetPointOfInterest:(UITapGestureRecognizer *)tapGesture {
    if (tapGesture.state == UIGestureRecognizerStateEnded) {
        CGPoint tapPoint = [tapGesture locationInView:self.backgroundView];
        [self.videoCamera setPointOfInterestInParentViewSpace:tapPoint];
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
    switch (self.videoCamera.defaultAVCaptureDevicePosition) {
        case AVCaptureDevicePositionFront:
            self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
            break;
        default:
            self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
            [self refresh];
            break;
    }
    [self refresh];
}

- (IBAction)onFace0ButtonPressed {
    faceToMerge0 = bestDetectedFace;
    [self showFace:faceToMerge0 inImageView:self.face0ImageView];
    if (!faceToMerge1.isEmpty()) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.mergeButton.enabled = YES;
        });
    }
}

- (IBAction)onFace1ButtonPressed {
    faceToMerge1 = bestDetectedFace;
    [self showFace:faceToMerge1 inImageView:self.face1ImageView];
    if (!faceToMerge0.isEmpty()) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.mergeButton.enabled = YES;
        });
    }
}

- (void)refresh {
    // Start or restart the video.
    [self.videoCamera stop];
    [self.videoCamera start];
}

- (void)processImage:(cv::Mat &)mat {

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
    
    // Detect and draw any faces.
    faceDetector->detect(mat, detectedFaces, DETECT_RESIZE_FACTOR, true);
    
    BOOL didDetectFaces = (detectedFaces.size() > 0);
    
    if (didDetectFaces) {
        // Find the biggest face.
        int bestFaceIndex = 0;
        for (int i = 0, bestFaceArea = 0; i < detectedFaces.size(); i++) {
            Face &detectedFace = detectedFaces[i];
            int faceArea = detectedFace.getWidth() * detectedFace.getHeight();
            if (faceArea > bestFaceArea) {
                bestFaceIndex = i;
                bestFaceArea = faceArea;
            }
        }
        bestDetectedFace = detectedFaces[bestFaceIndex];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.face0Button.enabled = didDetectFaces;
        self.face1Button.enabled = didDetectFaces;
    });
}

- (void)showFace:(Face &)face inImageView:(UIImageView *)imageView {
    imageView.image = [self imageFromCapturedMat:face.getMat()];
}

- (UIImage *)imageFromCapturedMat:(const cv::Mat &)mat {
    switch (mat.channels()) {
        case 4: {
            cv::Mat rgbMat;
            cv::cvtColor(mat, rgbMat, cv::COLOR_BGRA2RGB);
            return MatToUIImage(rgbMat);
        }
        default:
            // The source is grayscale.
            return MatToUIImage(mat);
    }
}

@end
