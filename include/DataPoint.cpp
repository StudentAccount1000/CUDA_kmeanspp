#ifndef DATAPOINT_CPP
#define DATAPOINT_CPP

#include "DataPoint.h"

DataPoint::DataPoint() : x(0), y(0)
{
}

DataPoint::DataPoint(const double _x, const double _y) : x(_x), y(_y)
{
}

double DataPoint::getX() const {
    return this->x;
}

double DataPoint::getY() const {
    return this->x;
}

#endif // DATAPOINT_CPP