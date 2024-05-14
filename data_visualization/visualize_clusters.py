import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

def plot_clustered_data(file_number: int, seq_or_cuda: int):
    filepath_prefix = ""
    if (seq_or_cuda == 1):
        filepath_prefix = "SEQ"
    elif (seq_or_cuda == 2):
        filepath_prefix = "CUDA"
    else:
        print("Invalid inputs")
        return

    # file path to read data
    file_path = f"../output/" + filepath_prefix + f"/output_csv/kmeans_{file_number}.csv"

    # plot clusters
    plt.figure()
    df = pd.read_csv(file_path)
    sns.scatterplot(x=df.y, y=df.x,
                    hue=df.c,
                    palette=sns.color_palette("hls", n_colors=file_number))
    plt.xlabel("latitude")
    plt.ylabel("longitude")
    plt.title(f"Baltimore Crime Locations K={file_number}")

    # save plot to file
    plt.savefig(f"../output/" + filepath_prefix + f"/output_png/kmeans_{file_number}.png")
    plt.show()

def main():
    file_number_str = input("Enter the number of clusters: ")
    seq_or_cuda_str = input("Enter 1 for SEQ, 2 for CUDA: ")
    try:
        file_number = int(file_number_str)
        seq_or_cuda = int(seq_or_cuda_str)
    except ValueError:
        print("Please enter a valid integer.")
    plot_clustered_data(file_number, seq_or_cuda)
if __name__ == "__main__":
    main()