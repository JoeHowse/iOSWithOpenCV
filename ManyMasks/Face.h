//
//  Face.h
//  ManyMasks
//
//  Created by Joseph Howse on 2016-03-05.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
//

#ifndef FACE_H
#define FACE_H

#include <opencv2/core.hpp>

#include "Species.h"

class Face {

public:
    Face(Species species, const cv::Mat &mat, const cv::Point2f &leftEyeCenter, const cv::Point2f &rightEyeCenter, const cv::Point2f &noseTip);
    
    /**
     * Construct an empty face.
     */
    Face();
    
    /**
     * Construct a face by copying another face.
     */
    Face(const Face &other);
    
    /**
     * Construct a face by merging two other faces.
     */
    Face(const Face &face0, const Face &face1);
    
    bool isEmpty() const;
    
    Species getSpecies() const;
    
    const cv::Mat &getMat() const;
    int getWidth() const;
    int getHeight() const;
    
    const cv::Point2f &getLeftEyeCenter() const;
    const cv::Point2f &getRightEyeCenter() const;
    const cv::Point2f &getNoseTip() const;
    
private:
    void initMergedFace(const Face &biggerFace, const Face &smallerFace);
    
    Species species;
    
    cv::Mat mat;
    
    cv::Point2f leftEyeCenter;
    cv::Point2f rightEyeCenter;
    cv::Point2f noseTip;
};

#endif // !FACE_H
