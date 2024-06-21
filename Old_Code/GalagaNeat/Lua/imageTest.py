from PIL import Image
import numpy as np
import sys
import imageio

def imageGen(filenames): 
    for name in filenames: 
        yield imageio.imread(name)

filename = sys.argv[1]

file = open(filename, 'r')

lines = [[int(float(val)*255) for val in line.strip().split()] for line in file]
filenames = []
"""
for i in range(len(lines)):
    arr = np.array(lines[i], dtype="uint8")
    arr = arr.reshape((28, 12))
    
    bigArr = np.zeros((28*20, 12*20), dtype="uint8")
    
    for j in range(28):
        for k in range(12):
            for n in range(20):
                for m in range(20):
                    bigArr[(20*j)+n][(20*k)+m] = arr[j][k]
    
    im = Image.fromarray(bigArr, mode='L')
    im.save("tmp/{}.png".format(i))
    filenames.append("tmp/{}.png".format(i))
    """
file.close()
for i in range(1660):
    filenames.append("tmp/{}.png".format(i))
imageio.mimsave("test.gif", imageGen(filenames))
