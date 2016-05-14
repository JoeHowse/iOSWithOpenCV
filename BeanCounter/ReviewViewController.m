//
//  ReviewViewController.m
//  BeanCounter
//
//  Created by Joseph Howse on 2016-03-12.
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

#import <Photos/Photos.h>
#import <Social/Social.h>

#import "ReviewViewController.h"

@interface ReviewViewController ()

@property IBOutlet UIImageView *imageView;
@property IBOutlet UILabel *label;
@property IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property IBOutlet UIToolbar *toolbar;

- (IBAction)onDeleteButtonPressed;
- (IBAction)onSaveButtonPressed;

- (void)saveImage:(UIImage *)image;
- (void)showSaveImageFailureAlertWithMessage:(NSString *)message;
- (void)showSaveImageSuccessAlertWithImage:(UIImage *)image;
- (UIAlertAction *)shareImageActionWithTitle:(NSString *)title serviceType:(NSString *)serviceType image:(UIImage *)image;
- (void)startBusyMode;
- (void)stopBusyMode;

@end

@implementation ReviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView.image = self.image;
    self.label.text = self.caption;
}

- (IBAction)onDeleteButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onSaveButtonPressed {
    [self startBusyMode];
    [self saveImage:self.image];
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
        [self dismissViewControllerAnimated:YES completion:nil];
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
            [self dismissViewControllerAnimated:YES completion:nil];
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

@end
