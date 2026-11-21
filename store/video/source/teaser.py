# Builds the 9:16 teaser (about 19 s) from the promo's screen clips.
# python3 teaser.py <work dir> <fonts dir> <logo.png> <badge.png> <en|ur> <out.mp4>
# The work dir holds build/c_*.mp4 (from build.py), bed.mp3 and vo_teaser_<lang>/<n>.mp3.
import sys, math, subprocess, json
from PIL import Image, ImageDraw, ImageFilter, ImageFont
S, F, LOGO, BADGE, LANG, OUT = sys.argv[1:7]
B = f'{S}/build'; T = f'{S}/teaser_{LANG}'
subprocess.run(['mkdir', '-p', T])
W, H = 1080, 1920
GOLD = (233, 196, 106); CREAM = (245, 241, 230); MUTED = (185, 199, 193)
UR = LANG == 'ur'

def font(name, size):
    return ImageFont.truetype(f'{F}/{name}', size, layout_engine=ImageFont.Layout.RAQM)

# ---- background
bg = Image.new('RGB', (W, H)); d = ImageDraw.Draw(bg)
for y in range(H):
    t = y / H
    d.line([(0, y), (W, y)], fill=(int(10 + (4 - 10) * t), int(34 + (9 - 34) * t), int(28 + (7 - 28) * t)))
glow = Image.new('L', (W, H), 0); ImageDraw.Draw(glow).ellipse((W / 2 - 620, 1150 - 620, W / 2 + 620, 1150 + 620), fill=95)
bg = Image.composite(Image.new('RGB', (W, H), (60, 52, 22)), bg, glow.filter(ImageFilter.GaussianBlur(170)))
lat = Image.new('L', (W, H), 0); g = ImageDraw.Draw(lat); step = 120
for cy in range(-step, H + step, step):
    for cx in range(-step, W + step, step):
        pts = [(cx + 34 * math.cos(math.radians(a)), cy + 34 * math.sin(math.radians(a))) for a in range(0, 360, 45)]
        for i in range(8): g.line([pts[i], pts[(i + 3) % 8]], fill=255, width=1)
mask = Image.new('L', (W, H), 0); g = ImageDraw.Draw(mask)
for y in range(H): g.line([(0, y), (W, y)], fill=int(14 * max(0, 1 - y / 900)))
bg = Image.composite(Image.new('RGB', (W, H), GOLD), bg, Image.composite(lat, Image.new('L', (W, H), 0), mask))
bg.save(f'{T}/bg.png')

# ---- phone: screen 700x1516 (runs off the bottom, under a fade)
SW, SH, BZ, M, R = 700, 1516, 18, 80, 76
PW, PH = SW + 2 * BZ + 2 * M, SH + 2 * BZ + 2 * M
PX, PY = (W - PW) // 2, 575 - M
ph = Image.new('RGBA', (PW, PH), (0, 0, 0, 0))
sh = Image.new('L', (PW, PH), 0); ImageDraw.Draw(sh).rounded_rectangle((M + 6, M + 34, PW - M + 6, PH - M + 34), R, fill=190)
ph.paste((0, 0, 0, 255), (0, 0), sh.filter(ImageFilter.GaussianBlur(38)))
d = ImageDraw.Draw(ph)
d.rounded_rectangle((M - 2, M - 2, PW - M + 2, PH - M + 2), R + 2, fill=(74, 78, 76, 255))
d.rounded_rectangle((M, M, PW - M, PH - M), R, fill=(12, 14, 13, 255))
d.rounded_rectangle((M + BZ, M + BZ, PW - M - BZ, PH - M - BZ), R - BZ, fill=(0, 0, 0, 0))
ph.save(f'{T}/phone.png')
sm = Image.new('L', (SW, SH), 0); ImageDraw.Draw(sm).rounded_rectangle((0, 0, SW - 1, SH - 1), R - BZ, fill=255); sm.save(f'{T}/mask.png')
# fade the bottom of the phone into the background
fade = Image.new('RGBA', (W, H), (0, 0, 0, 0)); fd = ImageDraw.Draw(fade)
for y in range(1500, H): fd.line([(0, y), (W, y)], fill=(4, 9, 7, int(255 * min(1, (y - 1500) / 330) ** 1.4)))
fade.save(f'{T}/fade.png')

# ---- captions
if UR:
    caps = [('تلاوت سنتے ہوئے', 'جگہ بھول جاتے ہیں؟'), ('ہر لفظ', 'تلاوت کے ساتھ چمکے'), ('کوئی بھی آیت', 'خوبصورتی سے شیئر کریں'), ('اپنی پلے لسٹس', 'یاد دہانی کے ساتھ')]
    kick = ['ون ورس', 'لفظ بہ لفظ', 'شیئر اسٹوڈیو', 'پلے لسٹس']
    tf, kf = font('NotoNastaliqUrdu-Bold.ttf', 76), font('NotoNastaliqUrdu-Bold.ttf', 34)
else:
    caps = [('Lost your place', 'while listening?'), ('Every word', 'lights up'), ('Share any ayah,', 'beautifully'), ('Playlists with', 'reminders')]
    kick = ['ONE VERSE', 'WORD BY WORD', 'SHARE STUDIO', 'PLAYLISTS']
    tf, kf = font('BricolageGrotesque-800.ttf', 98), font('Figtree-700.ttf', 32)

def caption(i, l1, l2, k):
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    dr = 'rtl' if UR else None
    y = 150
    kw = d.textlength(k, font=kf, direction=dr) + (0 if UR else 3 * len(k))
    pad = 26
    d.rounded_rectangle(((W - kw) / 2 - pad, y - (6 if UR else 14), (W + kw) / 2 + pad, y + (62 if UR else 44)), 40,
                        fill=(233, 196, 106, 34), outline=(233, 196, 106, 120), width=2)
    if UR:
        d.text((W / 2, y + 26), k, font=kf, fill=GOLD + (255,), anchor='mm', direction='rtl')
    else:
        x = (W - kw) / 2
        for ch in k: d.text((x, y - 6), ch, font=kf, fill=GOLD + (255,)); x += kf.getlength(ch) + 3
    y += 100 if UR else 86
    lh = 150 if UR else 108
    for j, line in enumerate((l1, l2)):
        col = CREAM if j == 0 else GOLD
        d.text((W / 2 + 3, y + 4 + lh / 2), line, font=tf, fill=(0, 0, 0, 120), anchor='mm', direction=dr)
        d.text((W / 2, y + lh / 2), line, font=tf, fill=col + (255,), anchor='mm', direction=dr)
        y += lh
    im.save(f'{T}/cap{i}.png')
for i, ((l1, l2), k) in enumerate(zip(caps, kick)): caption(i, l1, l2, k)

# ---- end card
end = bg.copy().convert('RGBA'); d = ImageDraw.Draw(end)
lg = Image.open(LOGO).convert('RGBA'); c = int(lg.width * 0.12); lg = lg.crop((c, c, lg.width - c, lg.height - c)).resize((300, 300), Image.LANCZOS)
cm = Image.new('L', (300, 300), 0); ImageDraw.Draw(cm).ellipse((0, 0, 299, 299), fill=255)
ring = Image.new('RGBA', (330, 330), (0, 0, 0, 0)); ImageDraw.Draw(ring).ellipse((0, 0, 329, 329), fill=GOLD + (255,))
end.alpha_composite(ring, ((W - 330) // 2, 455)); end.paste(lg, ((W - 300) // 2, 470), cm)
d.text((W / 2, 930), 'One Verse', font=font('BricolageGrotesque-800.ttf', 140), fill=CREAM + (255,), anchor='mm')
if UR:
    d.text((W / 2, 1080), 'قرآن سنیں، ہر لفظ ساتھ دیکھیں', font=font('NotoNastaliqUrdu-Bold.ttf', 58), fill=GOLD + (255,), anchor='mm', direction='rtl')
    d.text((W / 2, 1210), 'مفت · کوئی اشتہار نہیں · کوئی سائن اپ نہیں', font=font('NotoNastaliqUrdu-Regular.ttf', 40), fill=MUTED + (255,), anchor='mm', direction='rtl')
else:
    d.text((W / 2, 1060), 'Hear the Quran. See every word.', font=font('Figtree-700.ttf', 52), fill=GOLD + (255,), anchor='mm')
    d.text((W / 2, 1150), 'Free  ·  No ads  ·  No sign-up', font=font('Figtree-600.ttf', 42), fill=MUTED + (255,), anchor='mm')
bd = Image.open(BADGE).convert('RGBA'); bd = bd.resize((600, int(bd.height * 600 / bd.width)), Image.LANCZOS)
end.alpha_composite(bd, ((W - 600) // 2, 1330))
end.save(f'{T}/end.png')

# ---- timeline: (clip, start in clip, length)
segs = [('hook', 0.2, 3.6), ('hook', 3.8, 3.4), ('share', 1.6, 3.8), ('playlists', 3.0, 3.6)]
ENDLEN = 5.0
XF = 0.35
starts = []; t = 0
for _, _, ln in segs: starts.append(t); t += ln
end_t = t
total = end_t + ENDLEN

def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode: print(r.stderr[-3000:]); sys.exit(1)

inp = ['-loop', '1', '-framerate', '30', '-t', f'{total}', '-i', f'{T}/bg.png']
for c, _, _ in segs: inp += ['-i', f'{B}/c_{c}.mp4']
n0 = 1 + len(segs)
for f in ['phone.png', 'mask.png', 'fade.png', 'end.png'] + [f'cap{i}.png' for i in range(len(segs))]:
    inp += ['-loop', '1', '-framerate', '30', '-t', f'{total}', '-i', f'{T}/{f}']
iph, imask, ifade, iend, icap = n0, n0 + 1, n0 + 2, n0 + 3, n0 + 4
vo = json.load(open(f'{S}/vo_teaser_{LANG}/times.json'))
ivo = icap + len(segs)
for k in range(len(vo)): inp += ['-i', f'{S}/vo_teaser_{LANG}/{k}.mp3']
ibed = ivo + len(vo)
inp += ['-i', f'{S}/bed.mp3']

f = []
for i, (c, a, ln) in enumerate(segs):
    f.append(f'[{1 + i}:v]trim=start={a}:duration={ln},setpts=PTS-STARTPTS,fps=30,scale={SW}:{SH}:flags=lanczos,format=rgba[s{i}]')
f.append(''.join(f'[s{i}]' for i in range(len(segs))) + f'concat=n={len(segs)}:v=1:a=0,tpad=stop_mode=clone:stop_duration={ENDLEN + 1}[scr]')
f.append(f'[{imask}:v]format=gray[msk]')
f.append('[scr][msk]alphamerge[scrm]')
# phone rises in over the first 0.9 s, then breathes with a slow zoom
rise = f"{PY}+260*pow(1-min(t/0.9\\,1)\\,3)"
f.append(f"[0:v]format=rgba[bg]")
f.append(f"[bg][{iph}:v]overlay=x={PX}:y='{rise}':eval=frame[v1]")
f.append(f"[v1][scrm]overlay=x={PX + M + BZ}:y='{rise}+{M + BZ}':eval=frame[v2]")
f.append(f"[v2][{ifade}:v]overlay=0:0[v3]")
cur = 'v3'
for i in range(len(segs)):
    st, ln = starts[i], segs[i][2]
    if i == 1:  # same clip continues: swap the caption only
        pass
    f.append(f"[{icap + i}:v]format=rgba,fade=t=in:st={st + 0.05:.2f}:d=0.3:alpha=1,fade=t=out:st={st + ln - 0.3:.2f}:d=0.3:alpha=1[c{i}]")
    pop = f"-30*max(0\\,1-(t-{st:.2f})/0.35)"
    f.append(f"[{cur}][c{i}]overlay=x=0:y='{pop}':eval=frame:enable='between(t,{st:.2f},{st + ln:.2f})'[w{i}]")
    cur = f'w{i}'
f.append(f"[{iend}:v]format=rgba,fade=t=in:st={end_t - XF:.2f}:d={XF + 0.25}:alpha=1[endv]")
f.append(f"[{cur}][endv]overlay=0:0:enable='gte(t,{end_t - XF:.2f})'[w]")
f.append(f"color=c=0xE9C46A:s={W}x8:r=30:d={total}[bar]")
f.append(f"[w][bar]overlay=x='-{W}+{W}*t/{total}':y={H - 8}:eval=frame[wb]")
f.append(f"[wb]format=yuv420p,fade=t=out:st={total - 0.6:.2f}:d=0.6[vout]")
vl = []
for k, at in enumerate(vo):
    ms = int(at * 1000)
    f.append(f"[{ivo + k}:a]aformat=sample_rates=48000:channel_layouts=stereo,adelay={ms}|{ms}[a{k}]"); vl.append(f'[a{k}]')
f.append(f"{''.join(vl)}amix=inputs={len(vl)}:normalize=0,apad=whole_dur={total}[vo]")
f.append('[vo]asplit[vo1][vo2]')
f.append(f"[{ibed}:a]aformat=sample_rates=48000:channel_layouts=stereo,atrim=0:{total},volume=0.34,afade=t=in:st=0:d=0.6,afade=t=out:st={total - 2:.2f}:d=2[bed]")
f.append('[bed][vo2]sidechaincompress=threshold=0.02:ratio=6:attack=30:release=450:makeup=1[bedd]')
f.append(f"[vo1][bedd]amix=inputs=2:normalize=0,loudnorm=I=-14:TP=-1.5:LRA=11,atrim=0:{total}[aout]")
run(['ffmpeg', '-y', '-v', 'error', *inp, '-filter_complex', ';'.join(f), '-map', '[vout]', '-map', '[aout]', '-r', '30',
     '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-profile:v', 'high', '-pix_fmt', 'yuv420p',
     '-c:a', 'aac', '-b:a', '192k', '-ar', '48000', '-movflags', '+faststart', '-t', f'{total}', OUT])
print('done', OUT, round(total, 2))
