import PIL
from PIL import Image
import sys

img = Image.open(sys.argv[1])
width, baseheight = img.size

im = Image.open(sys.argv[2])
width, baseheight = im.size

hpercent = (baseheight / float(im.size[1]))
wsize = int((float(im.size[0]) * float(hpercent)))
img = img.resize((wsize, baseheight), PIL.Image.ANTIALIAS)
im.save(sys.argv[3])
