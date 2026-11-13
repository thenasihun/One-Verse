# Renders the static layers of the promo video: background, phone, mask, titles.
import sys, math
from PIL import Image, ImageDraw, ImageFilter, ImageFont
S = sys.argv[1]; F = sys.argv[2]  # build dir, fonts dir
W, H = 1920, 1080
GOLD = (233, 196, 106); INK = (5, 11, 9)
def font(name, size): return ImageFont.truetype(f'{F}/{name}', size)

# background
bg = Image.new('RGB', (W, H))
d = ImageDraw.Draw(bg)
for y in range(H):
    t = y / H
    d.line([(0, y), (W, y)], fill=(int(9 + (4 - 9) * t), int(30 + (10 - 30) * t), int(25 + (8 - 25) * t)))
glow = Image.new('L', (W, H), 0); g = ImageDraw.Draw(glow)
g.ellipse((1340 - 560, 540 - 560, 1340 + 560, 540 + 560), fill=90); glow = glow.filter(ImageFilter.GaussianBlur(160))
bg = Image.composite(Image.new('RGB', (W, H), (60, 52, 22)), bg, glow)
glow2 = Image.new('L', (W, H), 0); g = ImageDraw.Draw(glow2)
g.ellipse((-300, 600, 700, 1500), fill=110); glow2 = glow2.filter(ImageFilter.GaussianBlur(200))
bg = Image.composite(Image.new('RGB', (W, H), (8, 70, 52)), bg, glow2)
# faint eight-point star lattice
lat = Image.new('L', (W, H), 0); g = ImageDraw.Draw(lat)
step = 120
for cy in range(-step, H + step, step):
    for cx in range(-step, W + step, step):
        r = 34
        pts = [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a))) for a in range(0, 360, 45)]
        for i in range(8):
            g.line([pts[i], pts[(i + 3) % 8]], fill=255, width=1)
mask = Image.new('L', (W, H), 0); g = ImageDraw.Draw(mask)
for x in range(W):
    v = int(16 * max(0, (x - 900) / 1020))
    g.line([(x, 0), (x, H)], fill=v)
lat = Image.composite(lat, Image.new('L', (W, H), 0), mask)
bg = Image.composite(Image.new('RGB', (W, H), GOLD), bg, lat.point(lambda p: p * 0.35))
bg.save(f'{S}/bg.png')

# phone: screen 446x966, bezel 14, shadow margin 70
SW, SH, B, M, R = 446, 966, 14, 70, 54
PW, PH = SW + 2 * B + 2 * M, SH + 2 * B + 2 * M
ph = Image.new('RGBA', (PW, PH), (0, 0, 0, 0))
sh = Image.new('L', (PW, PH), 0); ImageDraw.Draw(sh).rounded_rectangle((M + 10, M + 30, PW - M + 10, PH - M + 30), R, fill=170)
sh = sh.filter(ImageFilter.GaussianBlur(34))
ph.paste((0, 0, 0, 255), (0, 0), sh)
d = ImageDraw.Draw(ph)
d.rounded_rectangle((M - 2, M - 2, PW - M + 2, PH - M + 2), R + 2, fill=(70, 74, 72, 255))
d.rounded_rectangle((M, M, PW - M, PH - M), R, fill=(12, 14, 13, 255))
d.rounded_rectangle((M + B, M + B, PW - M - B, PH - M - B), R - B, fill=(0, 0, 0, 0))
# side buttons
d.rounded_rectangle((PW - M, M + 190, PW - M + 5, M + 290), 2, fill=(55, 58, 56, 255))
d.rounded_rectangle((M - 5, M + 160, M, M + 220), 2, fill=(55, 58, 56, 255))
ph.save(f'{S}/phone.png')
sm = Image.new('L', (SW, SH), 0); ImageDraw.Draw(sm).rounded_rectangle((0, 0, SW - 1, SH - 1), R - B, fill=255)
sm.save(f'{S}/screenmask.png')
open(f'{S}/phone.txt', 'w').write(f'{PW} {PH} {M + B}')

# titles
icon = Image.open(sys.argv[3]).convert('RGBA')
def text_layer(name, kicker, title, body, extra=None):
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    x = 150
    tf, kf, bf = font('BricolageGrotesque-800.ttf', 78), font('Figtree-700.ttf', 25), font('Figtree-500.ttf', 31)
    lines = title.split('\n')
    th = len(lines) * 90
    bl = body.split('\n') if body else []
    total = 46 + th + (30 + len(bl) * 46 if bl else 0)
    y = (H - total) // 2 - 10
    # kicker with spacing
    kx = x
    d.rounded_rectangle((x, y + 4, x + 6, y + 30), 3, fill=GOLD + (255,))
    kx += 22
    for ch in kicker:
        d.text((kx, y), ch, font=kf, fill=GOLD + (255,)); kx += kf.getlength(ch) + 3
    y += 46
    for l in lines:
        d.text((x - 3, y), l, font=tf, fill=(245, 241, 230, 255)); y += 90
    y += 30
    for l in bl:
        d.text((x, y), l, font=bf, fill=(185, 199, 193, 255)); y += 46
    im.save(f'{S}/t_{name}.png')

scenes = [
 ('home', '01   HOME', 'The right surah\nfor every moment', 'Suggestions for Friday, mornings and nights.\nFavourites and bookmarks, one tap away.'),
 ('reader', '02   WORD BY WORD', 'Every word lights up\nas it is recited', 'The page follows the reciter by itself.'),
 ('scripts', '03   FIVE SCRIPTS', 'Madani, IndoPak,\nTajweed colours', 'Each script in the font it was made for.'),
 ('deck', '04   NEW PLAYER', 'Everything under\nyour thumb', 'Reciter  ·  Translation  ·  What you hear\nRepeat  ·  Speed'),
 ('translation', '05   TRANSLATIONS', '100+ translations,\n40+ languages', 'Urdu in Nastaliq. Hear the meaning\nafter every ayah.'),
 ('reciters', '06   RECITERS', '50+ reciters', 'Alafasy, Sudais, Maher Al-Muaiqly,\nSaad Al-Ghamdi and many more.'),
 ('memorise', '07   MEMORISE', 'Loop ayahs\nuntil they stay', '3, 5, 10 or 20 rounds, with a pause\nto recite from memory.'),
 ('tafseer', '08   TAFSEER', 'Understand\nevery ayah', 'Ibn Kathir  ·  Bayan ul Quran  ·  Ma’arif al-Qur’an\nin Urdu, English and Arabic.'),
 ('bookmark', '09   BOOKMARKS', 'Save ayahs\nwith your notes', 'Your reflections, kept with the ayah.'),
 ('progress', '10   HABITS & OFFLINE', 'Streaks, goals and\nthe Quran offline', 'Download the complete Quran\nand listen without internet.'),
]
for s in scenes: text_layer(*s)

def brand(name, tagline, sub, badge=None):
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    x = 150; y = 300
    ic = icon.resize((150, 150), Image.LANCZOS)
    im.alpha_composite(ic, (x - 6, y))
    y += 180
    d.text((x - 4, y), 'One Verse', font=font('BricolageGrotesque-800.ttf', 112), fill=(245, 241, 230, 255)); y += 132
    d.text((x, y), tagline, font=font('Figtree-600.ttf', 40), fill=GOLD + (255,)); y += 66
    if sub: d.text((x, y), sub, font=font('Figtree-500.ttf', 30), fill=(185, 199, 193, 255)); y += 60
    if badge:
        b = Image.open(badge).convert('RGBA'); b = b.resize((int(b.width * 0.62), int(b.height * 0.62)), Image.LANCZOS)
        im.alpha_composite(b, (x - 22, y))
    im.save(f'{S}/t_{name}.png')
brand('intro', 'Hear the Quran. See every word.', 'Free  ·  No ads  ·  No account')
brand('outro', 'Free  ·  No ads  ·  No account', 'nasihun.com', badge=sys.argv[4])
print('ok')
