from sklearn.cluster import KMeans
import numpy as np

file_path_num = int(input("Enter 1 for small, 2 for half, 3 for full data: "))
filepath = ""
datatype = ""
if (file_path_num == 1):
    datatype = "small"
    filepath = "../data/data_small.txt"
elif(file_path_num == 2):
    datatype = "half"
    filepath = "../data/data_half.txt"
elif(file_path_num == 3):
    datatype = "full"
    filepath = "../data/data_full.txt"
else:
    print("Invalid input.")
    exit(0)
# Read data points from file
data_points = []
with open(filepath, 'r') as file:
    for line in file:
        # Extract x and y coordinates from each line
        parts = line.strip()[1:-2].split(',')
        x = float(parts[0])
        y = float(parts[1])
        data_points.append([x, y])

data_points = np.array(data_points)

# Retrieve number of clusters from user (i.e., the number of initial centroids)
num_clusters = input("Enter K: ")
try:
    num_clusters = int(num_clusters)
except ValueError:
    print("Please enter a valid integer.")

# Perform KMeans++ initialization
kmeans = KMeans(n_clusters=num_clusters, init='k-means++')
kmeans.fit(data_points)

# Get the initial centroids
initial_centroids = kmeans.cluster_centers_

# Write initial centroids into a file
output_file = f"../data/{datatype}_centroids/k{str(num_clusters)}_centroids.txt"
with open(output_file, "w") as file:
    for centroid in initial_centroids:
        file.write(f"({centroid[0]}, {centroid[1]}),\n")

print("Initial centroids:")
print(initial_centroids)