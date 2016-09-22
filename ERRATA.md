# Errata and Updates

Here are the errata and updates for my book, [iOS Application Development with OpenCV 3](https://www.packtpub.com/application-development/ios-application-development-opencv).

## Page 4-5: Additional steps needed to run build_framework.py

OpenCV's build process depends on CMake. Before running `build_framework.py`, you must install CMake. You may obtain a `.dmg` installer from the [official CMake downloads page](https://cmake.org/download/). Alternatively, you may install CMake via a package manager such as MacPorts or Homebrew.

Also, before running `build_framework.py`, you should run the following command to give it executable permissions:

```
$ chmod +x <opencv_source_path>/platforms/ios/build_framework.py
```

When `build_framework.py` works properly, it prints either `** INSTALL SUCCEEDED **` or `** BUILD SUCCEEDED **`, depending on the version.
