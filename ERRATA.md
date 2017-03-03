# Errata and Updates

Here are the errata and updates for my book, [iOS Application Development with OpenCV 3](https://www.packtpub.com/application-development/ios-application-development-opencv). Where applicable, revisions have been applied to the source files in this repository.

## Compiler warnings about documentation in Xcode 8+

Since Xcode 8, new projects are configured by default to use the `-Wdocumentation` compiler flag. This means that the compiler raises warnings if the comments do not follow certain formatting conventions. OpenCV's headers contain many irregularly formatted comments, so you probably want to disable this flag to prevent a flood of unhelpful warnings. To disable it, go to the project's **Build Settings** pane, find the **Apple LLVM 8.0 - Warnings - All languages** section, and set the **Documentation Comments** entry to **No**.

## Additional `Info.plist` entries to support iOS 10+

Since iOS 10, if an app uses the camera and photo library, the `Info.plist` file must contain the `NSCameraUsageDescription` and `NSPhotoLibraryDescription` keys to describe the way the app uses these features. This new requirement affects the projects in Chapters 2-5. See the latest versions of the `Info.plist` files in this repository.

## Page 4-5: Additional steps to run `build_framework.py`

OpenCV's build process depends on CMake. Before running `build_framework.py`, you must install CMake. You may obtain a `.dmg` installer from the [official CMake downloads page](https://cmake.org/download/). Alternatively, you may install CMake via a package manager such as MacPorts or Homebrew.

Also, before running `build_framework.py`, you should run the following command to give it executable permissions:

```
$ chmod +x <opencv_source_path>/platforms/ios/build_framework.py
```

When `build_framework.py` works properly, it prints either `** INSTALL SUCCEEDED **` or `** BUILD SUCCEEDED **`, depending on the version.

## Page 24-25: New white balance API in `opencv_contrib`

The white balance API in `opencv_contrib` [changed on August 9, 2016](https://github.com/opencv/opencv_contrib/commit/75dedf9e589b1833d92b6bd644f64ae225795c96). The following code is updated to use the new API:

```
    case CV_8UC4: {
      // The cv::Mat is in RGBA format.
      // Convert it to RGB format.
      cv::cvtColor(originalMat, originalMat, cv::COLOR_RGBA2RGB);
#ifdef WITH_OPENCV_CONTRIB
      // Adjust the white balance.
      cv::Ptr<cv::xphoto::GrayworldWB> whiteBalancer = cv::xphoto::createGrayworldWB();
      whiteBalancer->balanceWhite(originalMat, originalMat);
#endif
      break;
    }
    case CV_8UC3: {
      // The cv::Mat is in RGB format.
#ifdef WITH_OPENCV_CONTRIB
      // Adjust the white balance.
      cv::Ptr<cv::xphoto::GrayworldWB> whiteBalancer = cv::xphoto::createGrayworldWB();
      whiteBalancer->balanceWhite(originalMat, originalMat);
#endif
      break;
    }
```

## Page 25: Repeating timer must be stopped

When an `NSTimer` is set up to fire on a repeating basis, it must be explicitly stopped. The following code is corrected to stop the timer when the application enters the background and restart the timer when the application enters the foreground.

```
  // Call an update method every 2 seconds.
  self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updateImage) userInfo:nil repeats:YES];
  
  // Get a notification center and queue.
  // These will provide notifications about application lifecycle events.
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  NSOperationQueue *queue = [NSOperationQueue mainQueue];
  
  // When the application enters the background, stop the update timer.
  [notificationCenter addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:queue usingBlock:^(NSNotification *note) {
    [self.timer invalidate];
    self.timer = nil;
  }];
  
  // When the application re-enters the foreground, restart the update timer.
  [notificationCenter addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:queue usingBlock:^(NSNotification *note) {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updateImage) userInfo:nil repeats:YES];
  }];
```

## Page 26: Mouse actions to connect an outlet

The paragraph beneath the heading "Connecting an interface element to the code" gives an incorrect description of the mouse actions. The following text is corrected:

> Let's connect the image view in `Main.Storyboard` to the imageView property in `ViewController.m`. Open `Main.Storyboard` in the project navigator and right-click (or *control*-click) on **View Controller** in the scene hierarchy. A dialog with a dark background appears. Inside this dialog, click on the circle beside **Outlets | imageView** and drag it to the **Piggy.png** image view in the scene hierarchy, as shown in the following screenshot:

## Page 48: Configuration of a `UIActivityIndicatorView`

After you add a `UIActivityIndicatorView`, go to the **Attributes** inspector and check the **Hides When Stopped** option.

## Page 73: Closing tokens

A set of closing tokens (`}];`) is missing from the code at the top of the page. The following code is corrected:

```
      animated:YES completion:^{
        [self stopBusyMode];
      }];
    }];
  return action;
}
```

## Page 96: Color conversion

At the end of the code excerpt, the color conversion logic fails to cover the cases where the source is already grayscale. The following code is corrected:

```
  switch (convertedBlendSrcMat.channels()) {
    case 1:
      if (!self.videoCamera.grayscaleMode) {
        cv::cvtColor(convertedBlendSrcMat, convertedBlendSrcMat, cv::COLOR_GRAY2BGRA);
      }
      break;
    default:
      if (self.videoCamera.grayscaleMode) {
        cv::cvtColor(convertedBlendSrcMat, convertedBlendSrcMat, cv::COLOR_RGBA2GRAY);
      } else {
        cv::cvtColor(convertedBlendSrcMat, convertedBlendSrcMat, cv::COLOR_RGBA2BGRA);
      }
      break;
  }
```

## Page 119-124: Changes in `refresh` method

Generally, these pages cover the changes in the `CaptureViewController` class between the old LightWork project and the new ManyMasks project. However, the book omits the changes in the `refresh` method's implementation. The following code is the correct implementation for ManyMasks:

```
- (void)refresh {
  [self.videoCamera stop];
  [self.videoCamera start];
}
```

## Page 123: Redundant `if` statement

The line `if (didDetectFaces) {` and the matching closing brace are mistakenly duplicated on this page. The following code is corrected to remove the redundancy:

```
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
```
