import json, subprocess, os, sys
S = sys.argv[1]; FR = f'{S}/frames'; B = f'{S}/build'
d = json.load(open(f'{FR}/index.json')); idx = d['index']; marks = d['marks']
XF = 0.4
# name, offset into the recorded scene, source length (None = to the end), target length
plan = [
 ('intro', 0, None, 7.0), ('home', 0, None, 6.5), ('reader', 0.3, 7.3, 7.3), ('scripts', 0, None, 7.8),
 ('deck', 0, None, 9.3), ('translation', 0, None, 8.3), ('reciters', 0, None, 5.4), ('memorise', 0, None, 7.8),
 ('tafseer', 0, None, 8.8), ('bookmark', 0, None, 4.4), ('progress', 0, 4.8, 7.6), ('outro', 0, None, 7.5),
]
def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode: print(' '.join(cmd)[:400]); print(r.stderr[-2500:]); sys.exit(1)

clips = []
for name, off, ln, target in plan:
    m = marks[name]; a = m['start'] + off; b = m['end'] if ln is None else a + ln
    fr = [(t, n) for t, n in idx if a <= t <= b]
    before = [(t, n) for t, n in idx if t < a]
    if before: fr = [(a, before[-1][1])] + fr
    lst = f'{B}/{name}.txt'
    with open(lst, 'w') as f:
        f.write('ffconcat version 1.0\n')
        for i, (t, n) in enumerate(fr):
            nxt = fr[i + 1][0] if i + 1 < len(fr) else b
            f.write(f"file '{FR}/{n}'\nduration {max(nxt - t, 0.001):.4f}\n")
        f.write(f"file '{FR}/{fr[-1][1]}'\n")
    src = b - a
    speed = src / target
    out = f'{B}/c_{name}.mp4'
    vf = f"setpts=PTS/{speed:.5f},fps=30,scale=892:1932:flags=lanczos,tpad=stop_mode=clone:stop_duration=3,trim=duration={target}"
    run(['ffmpeg', '-y', '-v', 'error', '-f', 'concat', '-safe', '0', '-i', lst, '-vf', vf, '-c:v', 'libx264', '-crf', '12', '-preset', 'fast', '-pix_fmt', 'yuv420p', '-an', out])
    clips.append((name, out, target))
    print(name, f'src {src:.1f}s -> {target}s (x{speed:.2f})')

# join screen clips with crossfades
inputs = []; fl = []; prev = '0:v'; t = clips[0][2]
for i, (_, f, _) in enumerate(clips): inputs += ['-i', f]
starts = [0.0]
for i in range(1, len(clips)):
    off = t - XF
    starts.append(off)
    lab = f'x{i}'
    fl.append(f'[{prev}][{i}:v]xfade=transition=fade:duration={XF}:offset={off:.3f}[{lab}]')
    prev = lab; t = off + clips[i][2]
total = t
run(['ffmpeg', '-y', '-v', 'error', *inputs, '-filter_complex', ';'.join(fl), '-map', f'[{prev}]', '-c:v', 'libx264', '-crf', '12', '-preset', 'fast', '-pix_fmt', 'yuv420p', f'{B}/screen.mp4'])
json.dump({'starts': starts, 'durs': [c[2] for c in clips], 'names': [c[0] for c in clips], 'total': total}, open(f'{B}/timeline.json', 'w'))
print('total', round(total, 2))
