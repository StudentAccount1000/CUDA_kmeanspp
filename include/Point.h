#ifndef POINT_H
#define POINT_H

#include "DataPoint.h"
#include <cfloat>

struct Point : DataPoint
{
        double minDist = DBL_MAX;
        int clusterID = -1;

        Point();
        Point(const double x, const double y);

        ~Point() = default;
};

#endif // POINT_H