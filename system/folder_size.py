###########################
# NAME: Folder Size       #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/12     #
# (C) 2022-2023           #
###########################

import os
import matplotlib.pyplot as plt
import sys


# We will check and return the folder/directory size in bytes.
def get_directory_size(directory):
    total = 0
    try:
        for entry in os.scandir(directory):
            if entry.is_file():
                # If we find a file use the "stat()" function.
                total += entry.stat().st_size
            elif entry.is_dir():
                # If we find a folder/directory call the following function.
                try:
                    total += get_directory_size(entry.path)
                # We will use "FileNotFoundError" if we find no files.
                except FileNotFoundError:
                    pass
    # We will use "NotADirectoryError" if we find no folder/directory.
    except NotADirectoryError:
        return os.path.getsize(directory)
    # If we cannot access the folder/directory return 0.
    except PermissionError:
        return 0
    return total


# Here is the size format scheme.
def get_size_format(b, factor=1024, suffix="B"):
    """Scale bytes to their proper format.
i.e.:
    1024000B (bytes) -> 1.024MB
    1024M (Megabytes) -> 1.00GB"""

    for unit in ["", "K", "M", "G", "T", "P", "E", "Z"]:
        if b < factor:
            return f"{b:.2f}{unit}{suffix}"
        b /= factor
    return f"{b:.2f}Y{suffix}"


# We will now plot the sizes in a pie chart.
def plot_pie(sizes, names):
    plt.pie(sizes, labels=names, autopct=lambda pct: f"{pct:.2f}%")
    plt.title("Sub directory sizes in bytes.")
    plt.show()


if __name__ == "__main__":
    folder_path = sys.argv[1]
    directory_sizes = []
    names = []
    # We will check the folder/directory inside the given path.
    for directory in os.listdir(folder_path):
        directory = os.path.join(folder_path, directory)
        # We will get the folder/directory size.
        directory_size = get_directory_size(directory)
        # If the folder/directory is empty, we will continue.
        if directory_size == 0:
            continue
        directory_sizes.append(directory_size)
        names.append(os.path.basename(directory) +
                     ": " + get_size_format(directory))
    print("[+] Total folder/directory size:",
          get_size_format(sum(directory_sizes)))
    plot_pie(directory_sizes, names)
