"""Pourfect Play Store promo video, LANDSCAPE 1920x1080, light (Toybox) look.

Adapted from Snake Classic's render_landscape.py. Captions on the left, the
phone recording on the right, on Pourfect's cream dotted ground.
Usage: python pourfect_render.py <ffmpeg.exe> <scenes.json> <music.wav> <out.mp4>
"""

import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

D = Path(__file__).parent
APP = Path(r"G:\Personal\MyProjects\Pourfect\pourfect_flutter_app")
FONTS = APP / "assets" / "fonts"
FF, SCENES, MUSIC, OUT = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
W, H = 1920, 1080

CREAM = (255, 243, 223)
INK = (31, 26, 51)
MUTED = (107, 100, 128)
TOMATO = (255, 90, 54)
YELLOW = (255, 194, 51)
BLUE = (61, 139, 255)
MINT = (34, 195, 166)
PINK = (255, 95, 143)
LILAC = (167, 139, 250)
WHITE = (255, 255, 255)

CHIPS = {"tomato": (TOMATO, WHITE), "yellow": (YELLOW, INK), "blue": (BLUE, WHITE),
         "mint": (MINT, INK), "pink": (PINK, WHITE), "lilac": (LILAC, INK)}

INTRO, OUTRO, FADE = 3.0, 4.5, 0.3

PH = 960
PW = round(PH * 1080 / 2340 / 2) * 2
PX, PY = 1270, (H - PH) // 2 - 6
RADIUS = 40
CAP_X, CAP_W = 150, 960


def bagel(size):
    return ImageFont.truetype(str(FONTS / "BagelFatOne-Regular.ttf"), size)


def outfit(weight, size):
    return ImageFont.truetype(str(FONTS / f"Outfit-{weight}.ttf"), size)


def wrap(draw, text, f, width):
    lines, cur = [], ""
    for word in text.split():
        trial = f"{cur} {word}".strip()
        if draw.textlength(trial, font=f) <= width:
            cur = trial
        else:
            lines.append(cur)
            cur = word
    return lines + [cur]


def toy_box(d, box, fill, radius, shadow=10, border=6):
    """Pourfect's chunky look: ink outline, ink drop below."""
    x0, y0, x1, y1 = box
    d.rounded_rectangle((x0, y0 + shadow, x1, y1 + shadow), radius=radius, fill=INK)
    d.rounded_rectangle(box, radius=radius, fill=INK)
    d.rounded_rectangle((x0 + border, y0 + border, x1 - border, y1 - border),
                        radius=max(radius - border, 4), fill=fill)


def chip(d, x, y, label, color):
    bg, fg = CHIPS.get(color, CHIPS["tomato"])
    f = outfit("ExtraBold", 34)
    tw = d.textlength(label, font=f) + 6 * (len(label) - 1)
    h = 70
    toy_box(d, (x, y, x + tw + 60, y + h), bg, 18, shadow=7, border=5)
    cx = x + 30
    for ch in label:
        d.text((cx, y + h / 2 + 1), ch, font=f, fill=fg, anchor="lm")
        cx += d.textlength(ch, font=f) + 6
    return y + h + 7


def caption_png(i, label, color, title, sub):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ft, fs = bagel(96), outfit("Medium", 46)
    tlines = wrap(d, title, ft, CAP_W)
    slines = wrap(d, sub, fs, CAP_W - 60)[:3]
    block = 77 + 44 + len(tlines) * 112 + 26 + len(slines) * 62
    y = (H - block) // 2
    y = chip(d, CAP_X, y, label, color) + 44
    for line in tlines:
        d.text((CAP_X - 2, y + 6), line, font=ft, fill=INK)  # ink drop, like the app's titles
        d.text((CAP_X - 4, y), line, font=ft, fill=INK)
        y += 112
    y += 26
    for line in slines:
        d.text((CAP_X, y), line, font=fs, fill=MUTED)
        y += 62
    p = D / f"pcap{i}.png"
    img.save(p)
    return p


def background():
    img = Image.new("RGB", (W, H), CREAM)
    d = ImageDraw.Draw(img, "RGBA")
    step = 36
    for y in range(step // 2, H, step):
        for x in range(step // 2, W, step):
            d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(31, 26, 51, 24))
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((-300, -350, 650, 500), fill=(255, 194, 51, 60))
    gd.ellipse((1150, 380, 2250, 1450), fill=(255, 90, 54, 38))
    glow = glow.filter(ImageFilter.GaussianBlur(150))
    img.paste(glow, (0, 0), glow)
    return img


def phone_assets():
    bg = background()
    d = ImageDraw.Draw(bg)
    # Chunky ink frame with a hard drop, in the app's own language.
    d.rounded_rectangle((PX - 14, PY - 14 + 16, PX + PW + 14, PY + PH + 14 + 16),
                        radius=RADIUS + 14, fill=INK)
    d.rounded_rectangle((PX - 14, PY - 14, PX + PW + 14, PY + PH + 14), radius=RADIUS + 14, fill=INK)
    bg.save(D / "pstage.png")
    mask = Image.new("L", (PW, PH), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, PW - 1, PH - 1), radius=RADIUS, fill=255)
    mask.save(D / "pmask.png")


def mark(size):
    return Image.open(APP / "assets" / "brand" / "logo_mark_1024.png").convert("RGBA").resize(
        (size, size), Image.LANCZOS)


def wordmark(d, cx, y, size, anchor="mm"):
    f = bagel(size)
    off = max(6, size // 18)
    d.text((cx + off * 0.4, y + off), "Pourfect", font=f, fill=INK, anchor=anchor)
    d.text((cx, y), "Pourfect", font=f, fill=TOMATO, anchor=anchor, stroke_width=max(3, size // 45),
           stroke_fill=INK)


def tagline(d, cx, y):
    f = outfit("ExtraBold", 36)
    text = "POUR · SORT · RELAX"
    w = sum(d.textlength(c, font=f) + 9 for c in text) - 9
    pad = 34
    d.rounded_rectangle((cx - w / 2 - pad, y - 36, cx + w / 2 + pad, y + 36), radius=16, fill=INK)
    x = cx - w / 2
    for c in text:
        d.text((x, y + 1), c, font=f, fill=CREAM, anchor="lm")
        x += d.textlength(c, font=f) + 9


def card(name, build):
    img = background()
    d = ImageDraw.Draw(img)
    build(img, d)
    p = D / f"{name}.png"
    img.save(p)
    return p


def intro(img, d):
    m = mark(260)
    img.paste(m, ((W - 260) // 2, 170), m)
    wordmark(d, W / 2, 610, 210)
    tagline(d, W / 2, 820)


def outro(img, d):
    m = mark(170)
    img.paste(m, (170, 150), m)
    wordmark(d, 360, 235, 150, anchor="lm")
    items = [("150 levels across 4 worlds", MINT), ("Zen mode: no clock, no stars", LILAC),
             ("A Daily Pour every day", BLUE), ("Plays offline. Color-blind friendly.", YELLOW)]
    fi = outfit("Bold", 48)
    y = 470
    for t, c in items:
        d.ellipse((190, y - 20, 230, y + 20), fill=c, outline=INK, width=5)
        d.text((262, y), t, font=fi, fill=INK, anchor="lm")
        y += 100
    bw, bh = 620, 150
    bx, by = 1150, 400
    toy_box(d, (bx, by, bx + bw, by + bh), TOMATO, 30, shadow=14, border=7)
    d.text((bx + bw / 2, by + bh / 2 + 2), "PLAY FREE NOW", font=bagel(64), fill=WHITE, anchor="mm")
    d.text((bx + bw / 2, by + bh + 80), "ON GOOGLE PLAY", font=outfit("ExtraBold", 40), fill=MUTED,
           anchor="mm")


def main():
    scenes = json.loads(Path(SCENES).read_text(encoding="utf-8"))["segments"]
    phone_assets()
    caps = [caption_png(i, s["chip"], s.get("color", "tomato"), s["title"], s["sub"])
            for i, s in enumerate(scenes)]
    intro_p, outro_p = card("pintro", intro), card("poutro", outro)
    if "--cards-only" in sys.argv:
        print("cards written")
        return

    durs = [s["b"] - s["a"] + s.get("hold", 0) for s in scenes]
    demo_len = sum(durs)
    total = INTRO + demo_len + OUTRO

    srcs = sorted({s["src"] for s in scenes})
    inputs, idx = [], {}
    for sp in srcs:
        idx[sp] = len(inputs) // 2
        inputs += ["-i", str(D / sp)]
    n_src = len(srcs)
    inputs += ["-loop", "1", "-i", str(D / "pstage.png")]
    inputs += ["-i", str(D / "pmask.png")]
    inputs += ["-loop", "1", "-t", str(INTRO), "-i", str(intro_p)]
    inputs += ["-loop", "1", "-t", str(OUTRO), "-i", str(outro_p)]
    cap0 = n_src + 4
    for p, du in zip(caps, durs):
        inputs += ["-loop", "1", "-t", f"{du:.3f}", "-i", str(p)]
    music_i = cap0 + len(scenes)
    inputs += ["-stream_loop", "-1", "-i", MUSIC]

    fc = []
    uses = {sp: [i for i, s in enumerate(scenes) if s["src"] == sp] for sp in srcs}
    for sp, ids in uses.items():
        k = idx[sp]
        outs = "".join(f"[r{i}]" for i in ids)
        fc.append(f"[{k}:v]fps=30,split={len(ids)}{outs}" if len(ids) > 1 else f"[{k}:v]fps=30{outs}")
    for i, s in enumerate(scenes):
        hold = f",tpad=stop_mode=clone:stop_duration={s['hold']}" if s.get("hold") else ""
        fc.append(f"[r{i}]trim={s['a']}:{s['b']},setpts=PTS-STARTPTS{hold}[t{i}]")
    fc.append("".join(f"[t{i}]" for i in range(len(scenes))) + f"concat=n={len(scenes)}:v=1:a=0[rec]")
    fc.append(f"[rec]scale={PW}:{PH}:flags=lanczos,format=rgba[ph]")
    fc.append(f"[{n_src + 1}:v]format=gray[mk]")
    fc.append("[ph][mk]alphamerge[phr]")
    fc.append(f"[{n_src}:v]fps=30,trim=0:{demo_len:.3f},setpts=PTS-STARTPTS[stg]")
    fc.append(f"[stg][phr]overlay={PX}:{PY}:shortest=1[a0]")
    last, t = "a0", 0.0
    for i, du in enumerate(durs):
        fades = f"fade=in:st=0:d={FADE}:alpha=1,fade=out:st={du - FADE:.3f}:d={FADE}:alpha=1"
        fc.append(f"[{cap0 + i}:v]format=rgba,{fades},setpts=PTS-STARTPTS+{t:.3f}/TB[c{i}]")
        fc.append(f"[{last}][c{i}]overlay=0:0:eof_action=pass[b{i}]")
        last, t = f"b{i}", t + du
    fc.append(f"color=c=0xFF5A36:s={W}x10:r=30:d={demo_len:.3f}[bar]")
    fc.append(f"[{last}][bar]overlay=x='-{W}+{W}*t/{demo_len:.3f}':y={H - 10}:shortest=1,"
              f"format=yuv420p,setsar=1[demo]")
    fc.append(f"[{n_src + 2}:v]fps=30,format=yuv420p,fade=in:st=0:d=0.35,fade=out:st={INTRO - 0.35}:d=0.35,setsar=1[in]")
    fc.append(f"[{n_src + 3}:v]fps=30,format=yuv420p,fade=in:st=0:d=0.35,fade=out:st={OUTRO - 0.6}:d=0.6,setsar=1[out]")
    fc.append("[in][demo][out]concat=n=3:v=1:a=0[v]")
    fc.append(f"[{music_i}:a]atrim=0:{total:.3f},asetpts=PTS-STARTPTS,aresample=48000,volume=0.9,"
              f"afade=in:st=0:d=0.6,afade=out:st={total - 1.8:.3f}:d=1.8[aud]")

    cmd = [FF, "-hide_banner", "-loglevel", "error", "-y", *inputs, "-filter_complex", ";".join(fc),
           "-map", "[v]", "-map", "[aud]", "-t", f"{total:.2f}", "-c:v", "libx264", "-crf", "19",
           "-preset", "slow", "-pix_fmt", "yuv420p", "-r", "30", "-c:a", "aac", "-b:a", "192k",
           "-movflags", "+faststart", OUT]
    subprocess.run(cmd, check=True)
    print("done", round(total, 2))


main()
