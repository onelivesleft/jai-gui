import os, glob, sys, cairosvg, io
from PIL import Image
from math import ceil, log; closest = lambda x: int(ceil(log(x) / log(2)))

ICON_SIZE = 64

if len(sys.argv) < 2:
    print(f"""
USAGE: {sys.argv[0]} <material-design-repo>

Creates sprite sheets in current folder from MDI repo, downloadable from
    https://github.com/Templarian/MaterialDesign
""")
    sys.exit(1)

folder = os.path.join(sys.argv[1], "svg")

icon_list = []
icon_path = {}

for icon_svg in glob.glob(os.path.join(folder, "*.svg")):
    icon_name = os.path.basename(icon_svg)[:-4].upper().replace("-", "_")
    assert not icon_name[0].isdigit(), path
    icon_list.append(icon_name)
    icon_path[icon_name] = icon_svg

icon_list.sort()

sheet_id = 0
icon_id = 1

sheet_cols = 64
sheet_rows = 2**closest(len(icon_list)//sheet_cols)
image_size = (sheet_cols * ICON_SIZE), (sheet_rows * ICON_SIZE)
image = Image.new("LA", image_size)


for icon_name in icon_list:
    print(icon_name)

    with open(icon_path[icon_name], 'r') as f:
        png = cairosvg.svg2png(file_obj=f, output_width=ICON_SIZE, output_height=ICON_SIZE)
    icon = Image.open(io.BytesIO(png))
    row = icon_id // sheet_cols
    col = icon_id % sheet_cols
    image.paste(icon, (col * ICON_SIZE, row * ICON_SIZE))

    icon_id += 1

image = image.split()[-1]
image.save(f"material_design_icons.png")

with open("../icons.jai",'w') as f:
    f.write("Icon_Id :: enum u16 {\n")
    f.write("    NONE;\n");
    for icon_name in icon_list:
        f.write(f"    {icon_name.upper()};\n")
    f.write("}\n\n")
    f.write(f"ICON_SHEET_COLUMN_COUNT :: {sheet_cols};\n")
    f.write(f"ICON_SHEET_ICON_SIZE :: {ICON_SIZE};\n")