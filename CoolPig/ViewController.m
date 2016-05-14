//
//  ViewController.m
//  CoolPig
//
//  Created by Joseph Howse on 2015-11-03.
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

#import <opencv2/core.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc.hpp>

#ifdef WITH_OPENCV_CONTRIB
#import <opencv2/xphoto.hpp>
#endif

#import "ViewController.h"


#define RAND_0_1() ((double)arc4random() / 0x100000000)


@interface ViewController () {
    cv::Mat originalMat;
    cv::Mat updatedMat;
}

@property IBOutlet UIImageView *imageView;
@property NSTimer *timer;

- (void)updateImage;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Load a UIImage from a resource file.
    UIImage *originalImage = [UIImage imageNamed:@"Piggy.png"];
    
    // Convert the UIImage to a cv::Mat.
    UIImageToMat(originalImage, originalMat);
    
    switch (originalMat.type()) {
        case CV_8UC1:
            // The cv::Mat is in grayscale format.
            // Convert it to RGB format.
            cv::cvtColor(originalMat, originalMat, cv::COLOR_GRAY2RGB);
            break;
        case CV_8UC4:
            // The cv::Mat is in RGBA format.
            // Convert it to RGB format.
            cv::cvtColor(originalMat, originalMat, cv::COLOR_RGBA2RGB);
#ifdef WITH_OPENCV_CONTRIB
            // Adjust the white balance.
            cv::xphoto::autowbGrayworld(originalMat, originalMat);
#endif
            break;
        case CV_8UC3:
            // The cv::Mat is in RGB format.
#ifdef WITH_OPENCV_CONTRIB
            // Adjust the white balance.
            cv::xphoto::autowbGrayworld(originalMat, originalMat);
#endif
            break;
        default:
            break;
    }
    
    // Call an update method every 2 seconds.
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updateImage) userInfo:nil repeats:YES];
}

- (void)updateImage {
    // Generate a random color.
    double r = 0.5 + RAND_0_1() * 1.0;
    double g = 0.6 + RAND_0_1() * 0.8;
    double b = 0.4 + RAND_0_1() * 1.2;
    cv::Scalar randomColor(r, g, b);
    
    // Create an updated, tinted cv::Mat by multiplying the original cv::Mat and the random color.
    cv::multiply(originalMat, randomColor, updatedMat);
    
    // Convert the updated cv::Mat to a UIImage and display it in the UIImageView.
    self.imageView.image = MatToUIImage(updatedMat);
}

@end
