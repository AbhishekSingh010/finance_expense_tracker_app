from PIL import Image, ImageDraw, ImageFont
import math

# Create a 1024x1024 image with a dark background
size = 1024
img = Image.new('RGB', (size, size), color='#121212')
draw = ImageDraw.Draw(img)

# Draw a gradient or solid circle
circle_bbox = [128, 128, 896, 896]
draw.ellipse(circle_bbox, fill='#6366F1') # Primary color from theme

# Draw another circle for the glass effect / overlapping
circle_bbox_2 = [256, 256, 1024, 1024]
draw.ellipse(circle_bbox_2, fill='#8B5CF6') # Secondary color

# Draw currency symbol
# Since we might not have a good font loaded, we'll draw a simple shapes or use default font
try:
    font = ImageFont.truetype("LiberationSans-Bold.ttf", 400)
except:
    font = ImageFont.load_default()

# We will just draw a text 'SM' for Spend Mind and a currency symbol
draw.text((size/2, size/2), "SM", fill="white", font=font, anchor="mm")

img.save('assets/icon.png')
