# Errata and Updates

Here are the errata and updates for my book, [iOS Application Development with OpenCV 3](https://www.packtpub.com/application-development/ios-application-development-opencv).

## Additional `Info.plist` entries to support iOS 10+

Since iOS 10, if an app uses the camera and photo library, the `Info.plist` file must contain the `NSCameraUsageDescription` and `NSPhotoLibraryDescription` keys to describe the way the app uses these features. This new requirement affects the projects in Chapters 2-5. See the latest versions of the `Info.plist` files in this repository.

## Page 4-5: Additional steps to run `build_framework.py`

OpenCV's build process depends on CMake. Before running `build_framework.py`, you must install CMake. You may obtain a `.dmg` installer from the [official CMake downloads page](https://cmake.org/download/). Alternatively, you may install CMake via a package manager such as MacPorts or Homebrew.

Also, before running `build_framework.py`, you should run the following command to give it executable permissions:

```
$ chmod +x <opencv_source_path>/platforms/ios/build_framework.py
```

When `build_framework.py` works properly, it prints either `** INSTALL SUCCEEDED **` or `** BUILD SUCCEEDED **`, depending on the version.

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
