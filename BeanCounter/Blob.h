//
//  Blob.h
//  BeanCounter
//
//  Created by Joseph Howse on 2016-04-09.
//  Copyright © 2016 Nummist Media Corporation Limited. All rights reserved.
//

#ifndef BLOB_H
#define BLOB_H

#include <opencv2/core.hpp>

class Blob
{
public:
    Blob(const cv::Mat &mat, uint32_t label = 0ul);
    
    /**
     * Construct an empty blob.
     */
    Blob();
    
    /**
     * Construct a blob by copying another blob.
     */
    Blob(const Blob &other);
    
    bool isEmpty() const;
    
    uint32_t getLabel() const;
    void setLabel(uint32_t value);
    
    const cv::Mat &getMat() const;
    int getWidth() const;
    int getHeight() const;
    
private:
    uint32_t label;
    
    cv::Mat mat;
};

#endif // BLOB_H
