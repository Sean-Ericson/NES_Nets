from PIL import Image
from PIL import ImageDraw
from PIL import ImageColor
import numpy as np
import sys
import imageio

PIC_WIDTH = 750
PIC_HEIGHT = 550
DRAW_WIDTH = 700
DRAW_HEIGHT = 500

def blueToRed(ratio):
    return (int(ratio*255), 0, int((1-ratio)*255))
    
file = open(sys.argv[1], 'r')
lines = [line.strip().split() for line in file]

inputs = int(lines[0][0])
outputs = int(lines[0][1])
hidden = 0
if (int(lines[0][2]) > 0):
    hidden = int(lines[0][2]) - inputs

total = inputs + hidden + outputs
width = int(DRAW_WIDTH / total)
if width > (DRAW_HEIGHT / 4):
    width = DRAW_HEIGHT / 4



image = Image.new('RGB', (750, 550), color="white")
draw =  ImageDraw.Draw(image)

#draw top neurons
border = (PIC_HEIGHT - DRAW_HEIGHT) / 2
bottom = border + width
for i in range(inputs):
    x1 = (i*width) + border
    y1 = border
    x2 = ((i+1)*width) + border
    y2 = bottom
    draw.rectangle([x1, y1, x2, y2], fill="grey", outline="black")
draw.rectangle([inputs*width + border, border, (inputs+1)*width + border, bottom], fill="white", outline="black")
for i in range(hidden):
    x1 = ((inputs+1+i)*width) + border
    y1 = border
    x2 = ((inputs+2+i)*width) + border
    y2 = bottom
    draw.rectangle([x1, y1, x2, y2], fill="grey", outline="black")
for i in range(outputs):
    x1 = ((inputs+hidden+1+i)*width) + border
    y1 = border
    x2 = ((inputs+hidden+2+i)*width) + border
    y2 = bottom
    draw.rectangle([x1, y1, x2, y2], fill="black")

#draw bottom neurons
top = PIC_HEIGHT - border - width
bottom = PIC_HEIGHT - border
for i in range(inputs):
    x1 = (i*width) + border
    y1 = top
    x2 = ((i+1)*width) + border
    y2 = bottom
    draw.rectangle([x1, y1, x2, y2], fill="grey", outline="black")
draw.rectangle([inputs*width + border, top, (inputs+1)*width + border, bottom], fill="white", outline="black")
for i in range(hidden):
    x1 = ((inputs+1+i)*width) + border
    y1 = top
    x2 = ((inputs+2+i)*width) + border
    y2 = bottom
    draw.rectangle([x1, y1, x2, y2], fill="grey", outline="black")
for i in range(outputs):
    x1 = ((inputs+hidden+1+i)*width) + border
    y1 = top
    x2 = ((inputs+hidden+2+i)*width) + border
    y2 = bottom
    draw.rectangle([x1, y1, x2, y2], fill="black")

image.save("prettyPic.png")

    
