# OsonGo launcher ikonkasi: binafsha fon, oq sumka, qoshiq va sanchqi.
from PIL import Image, ImageDraw
import os, sys
root = r'C:\Users\user\StudioProjects\Foodgo'
S = 1024
def art(rounded=True):
    top, bot = (140, 70, 255), (62, 10, 178)
    g = Image.new('RGB', (1, S))
    for y in range(S):
        t = y/(S-1); g.putpixel((0,y), tuple(int(a+(b-a)*t) for a,b in zip(top,bot)))
    bg = g.resize((S,S)).convert('RGBA')
    d = ImageDraw.Draw(bg)
    w = (255,255,255,255); p = (92,30,214,255)
    # sumka tutqichi va tanasi
    d.arc((470,215,700,470), 180, 360, fill=w, width=44)
    d.rounded_rectangle((360,350,810,800), radius=70, fill=w)
    # qoshiq
    d.ellipse((462,440,548,570), fill=p); d.rounded_rectangle((488,540,522,720), radius=17, fill=p)
    # sanchqi
    for x in (610,646,682): d.rounded_rectangle((x,440,x+20,540), radius=10, fill=p)
    d.rounded_rectangle((610,515,702,565), radius=24, fill=p)
    d.rounded_rectangle((639,540,673,720), radius=17, fill=p)
    # tezlik chiziqlari
    for x,y,x2 in ((190,455,325),(150,545,325),(215,635,325)):
        d.rounded_rectangle((x,y,x2,y+40), radius=20, fill=w)
    if rounded:
        m = Image.new('L',(S,S),0); ImageDraw.Draw(m).rounded_rectangle((0,0,S,S), radius=230, fill=255)
        bg.putalpha(m)
    return bg
def save(img, path, size):
    p = os.path.join(root, path); os.makedirs(os.path.dirname(p), exist_ok=True)
    img.resize((size,size), Image.LANCZOS).save(p)
r, sq = art(True), art(False)
save(r,'assets/icon/icon.png',512)
for n,s in (('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)):
    save(r,f'android/app/src/main/res/mipmap-{n}/ic_launcher.png',s)
save(r,'web/favicon.png',48); save(r,'web/icons/Icon-192.png',192); save(r,'web/icons/Icon-512.png',512)
save(sq,'web/icons/Icon-maskable-192.png',192); save(sq,'web/icons/Icon-maskable-512.png',512)
