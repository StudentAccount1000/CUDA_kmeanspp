#ifndef POINT_CPP
#define POINT_CPP

#include "Point.h"

Point::Point()
    : DataPoint()
    , minDist(DBL_MAX)
    , clusterID(-1)
{
};

Point::Point(const double x, const double y) 
    : DataPoint(x, y)
    , minDist(DBL_MAX)
    , clusterID(-1)
{
};

#endif // POINT_CPP