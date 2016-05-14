//
//  CaptureViewController.m
//  BeanCounter
//
//  Created by Joseph Howse on 2016-04-08.
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
#import "BlobClassifier.h"
#import "BlobDetector.h"
#import "ReviewViewController.h"
#import "VideoCamera.h"

const double DETECT_RESIZE_FACTOR = 0.5;

@interface CaptureViewController () <CvVideoCameraDelegate> {
    BlobClassifier *blobClassifier;
    BlobDetector *blobDetector;
    std::vector<Blob> detectedBlobs;
}

@property IBOutlet UIView *backgroundView;
@property IBOutlet UIBarButtonItem *classifyButton;

@property VideoCamera *videoCamera;
@property BOOL showMask;

@property NSArray<NSString *> *labelDescriptions;

- (IBAction)onTapToSetPointOfInterest:(UITapGestureRecognizer *)tapGesture;
- (IBAction)onPreviewModeSelected:(UISegmentedControl *)segmentedControl;
- (IBAction)onSwitchCameraButtonPressed;

- (void)refresh;
- (void)processImage:(cv::Mat &)mat;
- (UIImage *)imageFromCapturedMat:(const cv::Mat &)mat;

@end

@implementation CaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    blobDetector = new BlobDetector();
    blobClassifier = new BlobClassifier();
    
    // Load the blob classifier's configuration from file.
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *configPath = [bundle pathForResource:@"BlobClassifierTraining" ofType:@"plist"];
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:configPath];
    
    // Remember the descriptions of the blob labels.
    self.labelDescriptions = config[@"labelDescriptions"];
    
    // Create reference blobs and train the blob classifier.
    NSArray *configBlobs = config[@"blobs"];
    for (NSDictionary *configBlob in configBlobs) {
        uint32_t label = [configBlob[@"label"] unsignedIntValue];
        NSString *imageFilename = configBlob[@"imageFilename"];
        UIImage *image = [UIImage imageNamed:imageFilename];
        if (image == nil) {
            NSLog(@"Image not found in resources: %@", imageFilename);
            continue;
        }
        cv::Mat mat;
        UIImageToMat(image, mat);
        cv::cvtColor(mat, mat, cv::COLOR_RGB2BGR);
        Blob blob(mat, label);
        blobClassifier->update(blob);
    }
    
    self.videoCamera = [[VideoCamera alloc] initWithParentView:self.backgroundView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.letterboxPreview = YES;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
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
        
        // Stop the camera to prevent conflicting access to the blobs.
        [self.videoCamera stop];
        
        // Find the biggest blob.
        int biggestBlobIndex = 0;
        for (int i = 0, biggestBlobArea = 0; i < detectedBlobs.size(); i++) {
            Blob &detectedBlob = detectedBlobs[i];
            int blobArea = detectedBlob.getWidth() * detectedBlob.getHeight();
            if (blobArea > biggestBlobArea) {
                biggestBlobIndex = i;
                biggestBlobArea = blobArea;
            }
        }
        Blob &biggestBlob = detectedBlobs[biggestBlobIndex];
        
        // Classify the blob and show the result in the destination view controller.
        blobClassifier->classify(biggestBlob);
        reviewViewController.image = [self imageFromCapturedMat:biggestBlob.getMat()];
        reviewViewController.caption = self.labelDescriptions[biggestBlob.getLabel()];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    if (blobClassifier != NULL) {
        delete blobClassifier;
        blobClassifier = NULL;
    }
    if (blobDetector != NULL) {
        delete blobDetector;
        blobDetector = NULL;
    }
}

- (void)dealloc {
    if (blobClassifier != NULL) {
        delete blobClassifier;
        blobClassifier = NULL;
    }
    if (blobDetector != NULL) {
        delete blobDetector;
        blobDetector = NULL;
    }
}

- (IBAction)onTapToSetPointOfInterest:(UITapGestureRecognizer *)tapGesture {
    if (tapGesture.state == UIGestureRecognizerStateEnded) {
        CGPoint tapPoint = [tapGesture locationInView:self.backgroundView];
        [self.videoCamera setPointOfInterestInParentViewSpace:tapPoint];
    }
}

- (IBAction)onPreviewModeSelected:(UISegmentedControl *)segmentedControl {
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            self.showMask = NO;
            break;
        default:
            self.showMask = YES;
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
    
    // Detect and draw any blobs.
    blobDetector->detect(mat, detectedBlobs, DETECT_RESIZE_FACTOR, true);
    
    BOOL didDetectBlobs = (detectedBlobs.size() > 0);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.classifyButton.enabled = didDetectBlobs;
    });
    
    if (self.showMask) {
        blobDetector->getMask().copyTo(mat);
    }
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
