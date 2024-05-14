#ifndef IOFILE_H
#define IOFILE_H

#include <exception>
#include <stdio.h>
#include <string>
#include "Point.h"
#include "Centroid.h"

// read file to array
void read_file_to_arr(Point * &arr);
void read_file_to_arr(Centroid * &arr, const char* filepath);

// write array to csv
void write_array_to_csv(const std::string filepath_prefix, Point * &arr, const int& k_clusters);

// write centroid to txt
void write_centroids_to_txt(const std::string filepath_prefix, Centroid* &arr, const int& k_clusters);

#endif // IOFILE_H