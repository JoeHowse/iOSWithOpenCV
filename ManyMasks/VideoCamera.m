//
//  VideoCamera.m
//  ManyMasks
//
//  Created by Joseph Howse on 2015-12-11.
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

#import "VideoCamera.h"


@interface VideoCamera ()

@property (nonatomic, retain) CALayer *customPreviewLayer;

@end


@implementation VideoCamera

@synthesize customPreviewLayer = _customPreviewLayer;

- (int)imageWidth {
    AVCaptureVideoDataOutput *output = [self.captureSession.outputs lastObject];
    NSDictionary *videoSettings = [output videoSettings];
    int videoWidth = [[videoSettings objectForKey:@"Width"] intValue];
    return videoWidth;
}

- (int)imageHeight {
    AVCaptureVideoDataOutput *output = [self.captureSession.outputs lastObject];
    NSDictionary *videoSettings = [output videoSettings];
    int videoHeight = [[videoSettings objectForKey:@"Height"] intValue];
    return videoHeight;
}

- (void)updateSize {
    // Do nothing.
}

- (void)layoutPreviewLayer {
    if (self.parentView != nil) {
        
        // Center the video preview.
        self.customPreviewLayer.position = CGPointMake(0.5 * self.parentView.frame.size.width, 0.5 * self.parentView.frame.size.height);
        
        // Find the video's aspect ratio.
        CGFloat videoAspectRatio = self.imageWidth / (CGFloat)self.imageHeight;
        
        // Scale the video preview while maintaining its aspect ratio.
        CGFloat boundsW;
        CGFloat boundsH;
        if (self.imageHeight > self.imageWidth) {
            if (self.letterboxPreview) {
                boundsH = self.parentView.frame.size.height;
                boundsW = boundsH * videoAspectRatio;
            } else {
                boundsW = self.parentView.frame.size.width;
                boundsH = boundsW / videoAspectRatio;
            }
        } else {
            if (self.letterboxPreview) {
                boundsW = self.parentView.frame.size.width;
                boundsH = boundsW / videoAspectRatio;
            } else {
                boundsH = self.parentView.frame.size.height;
                boundsW = boundsH * videoAspectRatio;
            }
        }
        self.customPreviewLayer.bounds = CGRectMake(0.0, 0.0, boundsW, boundsH);
    }
}

- (void)setPointOfInterestInParentViewSpace:(CGPoint)parentViewPoint {
    
    if (!self.running) {
        return;
    }
    
    // Find the current capture device.
    NSArray *captureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice;
    for (captureDevice in captureDevices) {
        if (captureDevice.position == self.defaultAVCaptureDevicePosition) {
            break;
        }
    }
    
    BOOL canSetFocus = [captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && captureDevice.isFocusPointOfInterestSupported;
    
    BOOL canSetExposure = [captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose] && captureDevice.isExposurePointOfInterestSupported;
    
    if (!canSetFocus && ! canSetExposure) {
        return;
    }
    
    if (![captureDevice lockForConfiguration:nil]) {
        return;
    }
    
    // Find the preview's offset relative to the parent view.
    CGFloat offsetX = 0.5 * (self.parentView.bounds.size.width - self.customPreviewLayer.bounds.size.width);
    CGFloat offsetY = 0.5 * (self.parentView.bounds.size.height - self.customPreviewLayer.bounds.size.height);
    
    // Find the focus coordinates, proportional to the preview size.
    CGFloat focusX = (parentViewPoint.x - offsetX) / self.customPreviewLayer.bounds.size.width;
    CGFloat focusY = (parentViewPoint.y - offsetY) / self.customPreviewLayer.bounds.size.height;
    
    if (focusX < 0.0 || focusX > 1.0 || focusY < 0.0 || focusY > 1.0) {
        // The point is outside the preview.
        return;
    }
    
    // Adjust the focus coordinates based on the orientation.
    // They should be in the landscape-right coordinate system.
    switch (self.defaultAVCaptureVideoOrientation) {
        case AVCaptureVideoOrientationPortraitUpsideDown: {
            CGFloat oldFocusX = focusX;
            focusX = 1.0 - focusY;
            focusY = oldFocusX;
            break;
        }
        case AVCaptureVideoOrientationLandscapeLeft: {
            focusX = 1.0 - focusX;
            focusY = 1.0 - focusY;
            break;
        }
        case AVCaptureVideoOrientationLandscapeRight: {
            // Do nothing.
            break;
        }
        default: { // Portrait
            CGFloat oldFocusX = focusX;
            focusX = focusY;
            focusY = 1.0 - oldFocusX;
            break;
        }
    }
    
    if (self.defaultAVCaptureDevicePosition == AVCaptureDevicePositionFront) {
        // De-mirror the X coordinate.
        focusX = 1.0 - focusX;
    }
    
    CGPoint focusPoint = CGPointMake(focusX, focusY);
    
    if (canSetFocus) {
        // Auto-focus on the selected point.
        captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
        captureDevice.focusPointOfInterest = focusPoint;
    }
    
    if (canSetExposure) {
        // Auto-expose for the selected point.
        captureDevice.exposureMode = AVCaptureExposureModeAutoExpose;
        captureDevice.exposurePointOfInterest = focusPoint;
    }
    
    [captureDevice unlockForConfiguration];
}

@end
