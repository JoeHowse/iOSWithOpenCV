//
//  Face.h
//  ManyMasks
//
//  Created by Joseph Howse on 2016-03-05.
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
