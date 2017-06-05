# iOSWithOpenCV

These are the projects for my book, [iOS Application Development with OpenCV 3](https://www.packtpub.com/application-development/ios-application-development-opencv). For full details, please read the book along with the [Errata and Updates](ERRATA.md) page.

---

*&#9758; **I am using OpenCV 3** throughout the book and this repository. Even in OpenCV 3, the name `opencv2` still appears in header paths and in the filename `opencv2.framework`. Here, `opencv2` does not refer to the version number; it refers to the newer C++ API as opposed to the older C API.*

---

## Getting started

1. Set up an iOS development environment and OpenCV, as described in Chapter 1. If you run into difficulties in the section "Building the framework from source with extra modules", you may want to [download my build of `opencv2.framework`](https://github.com/JoeHowse/iOSWithOpenCV/releases/download/1.1.0/opencv2.framework.zip), which includes the `opencv_contrib` modules. Alternatively, some readers report that they are successfully using the [CocoaPods](https://cocoapods.org) dependency manager to obtain compatible pre-packaged builds of OpenCV (with or without the `opencv_contrib` modules).
2. Check out the repository to any path, which we will refer to as `<iOSWithOpenCV_path>`:

        $ git clone https://github.com/JoeHowse/iOSWithOpenCV.git <iOSWithOpenCV_path>
3. Put `opencv2.framework` in `<iOSWithOpenCV_path>`.
4. If your build of `opencv2.framework` does not contain the [opencv_contrib](https://github.com/Itseez/opencv_contrib) modules, edit each Xcode project's Build Settings | Preprocessor Macros to remove the `WITH_OPENCV_CONTRIB` flag.
5. Build and run the projects. Except for CoolPig, the projects use a camera, so they will work best on a real iOS device (not a simulator).

## Understanding the projects

Chapter 1 introduces the CoolPig project, which is a minimal example of integration between iOS SDK and OpenCV. The app loads an image of a pig and changes its tint based on a timer.

Chapters 2 and 3 iteratively develop the LightWork project, which is a photo-capture and -sharing application. Besides basic photographic features, it offers several filters to blend pairs of images.

Chapter 4 steps up to the ManyMasks project, which is a face blending app that works on humans, cats, and possibly other mammals. The approach relies on cascade classifiers to detect facial elements, and a geometric transformation to align them. It is scale-invariant and it can compensate for small differences in rotation.

Chapter 5 puts a capstone on the book with the BeanCounter project, which deals with object classification. The approach relies on blob detection, histogram analysis, and SURF (or ORB if SURF is unavailable). It is scale-invariant and rotation-invariant. Depending on a configuration file and a set of training images, the app could classify lots of things. Currently, it is configured to classify various Canadian coins and various beans.
