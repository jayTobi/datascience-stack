import os

# this is just sample python code
# normally something useful like model training would be done
# this is just for reflecting the changes in data size
# first version will include 1800 (1000 train, 800 validation) pictures
# second version will have 2800 (2000 train, 800 validation)

folder = os.getcwd() + "/data"
number_of_elements = sum([len(files) for r, d, files in os.walk(folder)])
print(f"Found {number_of_elements} elements in folder {folder}")
