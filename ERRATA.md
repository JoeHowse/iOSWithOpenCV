# Errata and Updates

Here are the errata and updates for my book, [iOS Application Development with OpenCV 3](https://www.packtpub.com/application-development/ios-application-development-opencv).

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
