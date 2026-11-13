import json, subprocess, sys
S = sys.argv[1]; B = f'{S}/build'; OUT = sys.argv[2]
tl = json.load(open(f'{B}/timeline.json'))
starts, durs, names, total = tl['starts'], tl['durs'], tl['names'], tl['total']
PW, PH, IN = map(int, open(f'{B}/phone.txt').read().split())
X0, Y0 = 1340 - PW // 2, 540 - PH // 2
inputs = ['-loop', '1', '-framerate', '30', '-t', f'{total}', '-i', f'{B}/bg.png',
          '-i', f'{B}/screen.mp4',
          '-loop', '1', '-framerate', '30', '-t', f'{total}', '-i', f'{B}/phone.png',
          '-loop', '1', '-framerate', '30', '-t', f'{total}', '-i', f'{B}/screenmask.png']
for n in names:
    inputs += ['-loop', '1', '-framerate', '30', '-t', f'{total}', '-i', f'{B}/t_{n}.png']
vo0 = len(inputs) // 2  # not used
nimg = 4 + len(names)
vo_delay = {'intro': 0.75, 'outro': 0.6}
for n in names:
    inputs += ['-i', f'{S}/vo/{n}.mp3']
inputs += ['-i', f'{S}/bed.mp3']
bed_i = nimg + len(names)

ease = "pow(1-min(t/1.1\\,1)\\,3)"
px = f"{X0}+{1920 - X0 + 40}*{ease}"
f = []
f.append(f"[0:v]format=rgba[bg]")
f.append(f"[1:v]scale=446:966:flags=lanczos,format=rgba[scr]")
f.append(f"[3:v]format=gray,scale=446:966[msk]")
f.append(f"[scr][msk]alphamerge[scrm]")
f.append(f"[bg][2:v]overlay=x='{px}':y={Y0}:eval=frame[v1]")
f.append(f"[v1][scrm]overlay=x='{px}+{IN}':y={Y0 + IN}:eval=frame[v2]")
cur = 'v2'
for i, n in enumerate(names):
    t0, du = starts[i], durs[i]
    fin = t0 + (0.9 if n == 'intro' else 0.3)
    chain = f"[{4 + i}:v]format=rgba,fade=t=in:st={fin:.3f}:d=0.5:alpha=1"
    if n != 'outro':
        chain += f",fade=t=out:st={t0 + du - 0.6:.3f}:d=0.4:alpha=1"
    f.append(chain + f"[t{i}]")
    slide = f"-36*max(0\\,1-(t-{fin:.3f})/0.55)"
    f.append(f"[{cur}][t{i}]overlay=x='{slide}':y=0:eval=frame:enable='between(t,{t0:.3f},{t0 + du:.3f})'[w{i}]")
    cur = f'w{i}'
f.append(f"color=c=0xE9C46A:s=1920x5:r=30:d={total}[bar]")
f.append(f"[{cur}][bar]overlay=x='-1920+1920*t/{total}':y=1075:eval=frame[w]")
f.append(f"[w]format=yuv420p,fade=t=in:st=0:d=0.5,fade=t=out:st={total - 0.9:.3f}:d=0.9[vout]")
# audio
vo = []
for i, n in enumerate(names):
    ms = int((starts[i] + vo_delay.get(n, 0.35)) * 1000)
    f.append(f"[{nimg + i}:a]aformat=sample_rates=48000:channel_layouts=stereo,adelay={ms}|{ms},volume=1.0[a{i}]")
    vo.append(f"[a{i}]")
f.append(f"{''.join(vo)}amix=inputs={len(vo)}:normalize=0,apad=whole_dur={total}[vo]")
f.append("[vo]asplit[vo1][vo2]")
f.append(f"[{bed_i}:a]aformat=sample_rates=48000:channel_layouts=stereo,atrim=0:{total},volume=0.30,afade=t=in:st=0:d=1.5,afade=t=out:st={total - 3.5:.3f}:d=3.5[bed]")
f.append("[bed][vo2]sidechaincompress=threshold=0.02:ratio=6:attack=30:release=500:makeup=1[bedd]")
f.append(f"[vo1][bedd]amix=inputs=2:normalize=0,loudnorm=I=-16:TP=-1.5:LRA=11,atrim=0:{total}[aout]")
cmd = ['ffmpeg', '-y', '-v', 'error', *inputs, '-filter_complex', ';'.join(f), '-map', '[vout]', '-map', '[aout]',
       '-r', '30', '-c:v', 'libx264', '-preset', 'slow', '-crf', '17', '-profile:v', 'high', '-pix_fmt', 'yuv420p',
       '-c:a', 'aac', '-b:a', '192k', '-ar', '48000', '-movflags', '+faststart', '-t', f'{total}', OUT]
r = subprocess.run(cmd, capture_output=True, text=True)
if r.returncode: print(r.stderr[-3000:]); sys.exit(1)
print('done', OUT)
