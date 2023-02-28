import os

import qrcode

img = qrcode.make(input("Please paste the link: "))
img.save("qr.png", "PNG")

# on linux or macos instead "start" need to use "open"
os.system("start qr.png")
