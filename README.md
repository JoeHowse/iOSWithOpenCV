# iOSWithOpenCV
These are the projects for my upcoming book, [iOS Application Development with OpenCV 3](https://www.packtpub.com/application-development/ios-application-development-opencv).

## Getting started
1. Check out the repository to any path, which we will refer to as `<iOSWithOpenCV_path>`.
2. Put `opencv2.framework` in `<iOSWithOpenCV_path>`.
3. If your build of `opencv2.framework` does not contain the [opencv_contrib](https://github.com/Itseez/opencv_contrib) modules, edit each Xcode project's Build Settings | Preprocessor Macros to remove the `WITH_OPENCV_CONTRIB` flag.
4. Build and run the projects. Except for CoolPig, the projects use a camera, so they will work best on a real iOS device (not a simulator).
