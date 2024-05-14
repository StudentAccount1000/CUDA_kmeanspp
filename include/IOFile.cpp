#include "IOFile.h"

#ifndef DATA_LENGTH
// #define DATA_LENGTH 2000
#define DATA_LENGTH 140000
// #define DATA_LENGTH 283894
#endif

// read file to array
void read_file_to_arr(Point * &arr) {
    // open file for read
    FILE* inputFile = fopen("data/data_half.txt", "r");
    if (inputFile == NULL) {
        // if open fail, throw runtime_error
        perror("Error opening the file");
        return;
    }

    // declare buffer
    double latitude, longitude = 0;
    int curr_index = 0;

    // scan line by line and write to array
    while (fscanf(inputFile, "(%lf, %lf),\n", &latitude, &longitude) == 2 && curr_index < DATA_LENGTH) {
        Point *p = new Point();
        p->x = latitude;
        p->y = longitude;
        arr[curr_index] = *p;
        curr_index++;
    }

    // one more iteration for the last line
    if (fscanf(inputFile, "(%lf, %lf)", &latitude, &longitude) == 2) {
        Point *p = new Point();
        p->x = latitude;
        p->y = longitude;
        arr[curr_index] = *p;
        curr_index++;
    }

    fclose(inputFile);
}

// read file to centroid
void read_file_to_arr(Centroid * &arr, const char* filepath) {
    // open file for read
    FILE* inputFile = fopen(filepath, "r");
    if (inputFile == NULL) {
        // if open fail, throw runtime_error
        perror("Error opening the file");
        return;
    }

    // declare buffer
    double latitude, longitude = 0;
    int curr_index = 0;

    // scan line by line
    while (fscanf(inputFile, "(%lf, %lf),\n", &latitude, &longitude) == 2) {
        Centroid *c = new Centroid();
        c->x = latitude;
        c->y = longitude;
        c->id = curr_index;
        arr[curr_index] = *c;
        curr_index++;
    }

    // one more iteration for the last line
    if (fscanf(inputFile, "(%lf, %lf)", &latitude, &longitude) == 2) {
        Centroid *c = new Centroid();
        c->x = latitude;
        c->y = longitude;
        c->id = curr_index;
        arr[curr_index] = *c;
        curr_index++;
    }

    fclose(inputFile);
}

// write array to file
void write_array_to_csv(const std::string filepath_prefix, Point * &arr, const int& k_clusters) {
    std::string filepath = "./output/" + filepath_prefix + "/output_csv/kmeans_" + std::to_string(k_clusters) + ".csv";
    // open file for write
    FILE* outputFile = fopen(filepath.c_str(), "w");
    if (outputFile == NULL) {
        // if open fail, throw runtime_error
        perror("Error opening the file");
        return;
    }

    fprintf(outputFile, "x,y,c\n");

    for (int i = 0; i < DATA_LENGTH; i++) {
        fprintf(outputFile, "%.5lf,%.5lf,%d\n", arr[i].x, arr[i].y, arr[i].clusterID);
    }

    fclose(outputFile);
    return;
}

void write_centroids_to_txt(const std::string filepath_prefix, Centroid* &arr, const int& k_clusters) {
    std::string filepath = "./output/" + filepath_prefix + "/output_centroids/kmeans_" + std::to_string(k_clusters) + ".txt";
    FILE * outputFile = fopen(filepath.c_str(), "w");
    if (outputFile == NULL) {
        perror("Error opening file");
        return;
    }

    fprintf(outputFile, "K is %d\n", k_clusters);

    for (int i = 0; i < k_clusters; i++) {
        fprintf(outputFile, "x: %.5lf, y: %.5lf, nPoints: %d, id: %d\n", arr[i].x, arr[i].y, arr[i].nPoints, arr[i].id);
    }

    fclose(outputFile);
    return;
}
