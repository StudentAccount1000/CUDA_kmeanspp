import pandas as pd

def extract_locations(num_rows, input_file="../data/og_data.csv", output_file="../data/data.txt"):
    # Read the dataset
    data = pd.read_csv(input_file)

    # drop null values
    data.dropna(subset=["Location 1"], inplace=True)

    # Filter data based on bounding coordinates for Baltimore City
    # Extract latitude and longitude values from "Location 1" column
    # Bounding coordinates found here: https://msgic.org/table-of-bounding-coordinates/
    data[['Latitude', 'Longitude']] = data['Location 1'].str.extract(r'\(([\d.-]+),\s+([\d.-]+)\)', expand=True).astype(float)
    baltimore_data = data[(data['Latitude'] >= 39.1977) & (data['Latitude'] <= 39.3719) & (data['Longitude'] >= -76.7122) & (data['Longitude'] <= -76.5294)]

    # Extract the "Location" column for the specified number of rows
    locations = baltimore_data["Location 1"].head(num_rows)

    print(locations)

    # Save the locations into a txt file
    with open(output_file, "w") as file:
        for location in locations:
            file.write(location + ",\n")

# Example usage:
output_filepath = ""
output_file_num = int(input("Enter 1 for small, 2 for half, 3 for full dataset: "))
if (output_file_num == 1):
    num_rows = 2000
    output_filepath = "../data/data_small.txt"
elif (output_file_num == 2):
    num_rows = 140000
    output_filepath = "../data/data_half.txt"
elif (output_file_num == 3):
    num_rows = 285808
    output_filepath = "../data/data_full.txt"
else:
    print("Invalid input.")
    exit(0)
extract_locations(num_rows, output_file=output_filepath)