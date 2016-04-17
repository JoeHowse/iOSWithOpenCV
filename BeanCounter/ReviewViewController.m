//
//  ReviewViewController.m
//  BeanCounter
//
//  Created by Joseph Howse on 2016-03-12.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
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
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Saved image" message:@"The image has been added to your Photos library. Would you like to share it with your friends?" preferredStyle:UIAlertControllerStyleAlert];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        UIAlertAction *facebookAction = [self shareImageActionWithTitle:@"Post on Facebook" serviceType:SLServiceTypeFacebook image:image];
        [alert addAction:facebookAction];
    }
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        UIAlertAction *twitterAction = [self shareImageActionWithTitle:@"Tweet" serviceType:SLServiceTypeTwitter image:image];
        [alert addAction:twitterAction];
    }
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]) {
        UIAlertAction *sinaWeiboAction = [self shareImageActionWithTitle:@"Post on Sina Weibo" serviceType:SLServiceTypeSinaWeibo image:image];
        [alert addAction:sinaWeiboAction];
    }
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTencentWeibo]) {
        UIAlertAction *tencentWeiboAction = [self shareImageActionWithTitle:@"Post on Tencent Weibo" serviceType:SLServiceTypeTencentWeibo image:image];
        [alert addAction:tencentWeiboAction];
    }
    
    UIAlertAction *doNotShareAction = [UIAlertAction actionWithTitle:@"Do not share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self stopBusyMode];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:doNotShareAction];
    
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
