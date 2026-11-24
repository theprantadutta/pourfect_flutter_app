"""Alternative Play Store icons for Pourfect (Toybox style).

Everything is laid out in 512-space units and rendered at 4x (2048 px), then
downsampled with LANCZOS.
"""
import math
import os
from PIL import Image, ImageDraw, ImageChops, ImageFont

OUT = os.path.dirname(os.path.abspath(__file__))
S = 4
N = 512 * S

INK = (31, 26, 51)
WHITE = (255, 255, 255)
TOMATO = (255, 90, 54)
BLUE = (61, 139, 255)
CREAM = (255, 243, 223)

BALLS = {
    "amber": ((255, 194, 51), "dot"),
    "azure": ((61, 139, 255), "ring"),
    "rose": ((255, 95, 143), "triangle"),
    "teal": ((34, 195, 166), "square"),
    "iris": ((167, 139, 250), "plus"),
}

STROKE_BOOST = 1.25  # brand stroke scaled up, a touch heavier for 48 px reading


def u(v):
    return v * S


# ---------------------------------------------------------------- primitives

def ellipse_mask(size, box):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).ellipse(box, fill=255)
    return m


def solid(size, rgb, mask):
    layer = Image.new("RGBA", size, rgb + (0,))
    layer.putalpha(mask)
    return layer


def scale_mask(mask, a):
    return mask.point(lambda p: int(p * a))


def ball_layer(D, name, k):
    """A ball of diameter D (render px). k = render px per brand unit (40px ball)."""
    color, glyph = BALLS[name]
    s = 2.5 * k * STROKE_BOOST
    pad = int(math.ceil(s)) + 4
    size = int(math.ceil(D)) + 2 * pad
    c = size / 2
    sz = (size, size)
    layer = Image.new("RGBA", sz, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    r = D / 2
    d.ellipse((c - r, c - r, c + r, c + r), fill=INK + (255,))
    ri = r - s
    inner = (c - ri, c - ri, c + ri, c + ri)
    d.ellipse(inner, fill=color + (255,))
    fill_m = ellipse_mask(sz, inner)
    # inner bottom shade: what the fill circle loses when shifted up by 4/40 D
    dy = 0.10 * D
    up = ellipse_mask(sz, (inner[0], inner[1] - dy, inner[2], inner[3] - dy))
    shade = ImageChops.subtract(fill_m, up)
    layer.alpha_composite(solid(sz, (0, 0, 0), scale_mask(shade, 0.16)))
    # top highlight
    dh = 0.075 * D
    down = ellipse_mask(sz, (inner[0], inner[1] + dh, inner[2], inner[3] + dh))
    hi = ImageChops.subtract(fill_m, down)
    layer.alpha_composite(solid(sz, WHITE, scale_mask(hi, 0.45)))
    # glyph
    d = ImageDraw.Draw(layer)
    g = INK + (255,)
    if glyph == "dot":
        gr = 0.26 * D / 2
        d.ellipse((c - gr, c - gr, c + gr, c + gr), fill=g)
    elif glyph == "ring":
        ro = 0.46 * D / 2
        rh = ro * 0.48
        d.ellipse((c - ro, c - ro, c + ro, c + ro), fill=g)
        d.ellipse((c - rh, c - rh, c + rh, c + rh), fill=color + (255,))
    elif glyph == "triangle":
        w, h = 0.42 * D, 0.37 * D
        cy = c + h * 0.06  # optical centring
        d.polygon([(c, cy - h / 2), (c + w / 2, cy + h / 2), (c - w / 2, cy + h / 2)], fill=g)
    elif glyph == "square":
        a = 0.32 * D / 2
        d.rounded_rectangle((c - a, c - a, c + a, c + a), radius=a * 0.22, fill=g)
    elif glyph == "plus":
        a = 0.46 * D / 2
        t = 0.135 * D / 2
        d.rounded_rectangle((c - a, c - t, c + a, c + t), radius=t * 0.6, fill=g)
        d.rounded_rectangle((c - t, c - a, c + t, c + a), radius=t * 0.6, fill=g)
    return layer


def tube_shape(d, x0, y0, x1, y1, rtop, fill):
    w = x1 - x0
    rb = w / 2
    d.rounded_rectangle((x0, y0, x1, y1 - rb), radius=rtop, fill=fill)
    d.rectangle((x0, y0 + rtop, x1, y1 - rb), fill=fill)
    d.ellipse((x0, y1 - w, x1, y1), fill=fill)


def tube_layer(W, balls, tube_fill=WHITE, top_gap_extra=0.0, draw_balls=True, centres=None):
    """Upright tube of width W (render px) with balls listed bottom-up."""
    k = W / 54.0
    H = 186 * k
    s = 2.5 * k * STROKE_BOOST
    m = int(math.ceil(s)) + 4
    size = (int(math.ceil(W)) + 2 * m, int(math.ceil(H)) + 2 * m)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0, y0, x1, y1 = m, m, m + W, m + H
    tube_shape(d, x0, y0, x1, y1, 12 * k, INK + (255,))
    tube_shape(d, x0 + s, y0 + s, x1 - s, y1 - s, max(12 * k - s, 1), tube_fill + (255,))
    D = 41 * k
    pad = 4 * k
    gap = 2 * k
    cx = m + W / 2
    for i, name in enumerate(balls):
        if name is None:
            continue
        cy = y1 - pad - D / 2 - i * (D + gap)
        if centres is not None:
            centres.append((name, cx - size[0] / 2, cy - size[1] / 2, D))
        if not draw_balls:
            continue
        b = ball_layer(D, name, D / 40.0)
        layer.alpha_composite(b, (int(round(cx - b.width / 2)), int(round(cy - b.height / 2))))
    return layer


def place(canvas, layer, cx, cy, shadow_dy, angle=0.0):
    """Paste layer centred at (cx, cy) render px, optionally rotated (degrees,
    clockwise), with a hard ink shadow offset straight down."""
    if angle:
        layer = layer.rotate(-angle, resample=Image.BICUBIC, expand=True)
    x = int(round(cx - layer.width / 2))
    y = int(round(cy - layer.height / 2))
    if shadow_dy:
        sh = Image.new("RGBA", layer.size, INK + (0,))
        sh.putalpha(layer.getchannel("A"))
        canvas.alpha_composite(sh, (x, y + int(round(shadow_dy))))
    canvas.alpha_composite(layer, (x, y))
    return layer


def place_tube(canvas, W, balls, cx, cy, shadow_dy, angle=0.0, fill=WHITE):
    """Tube rotated as a whole; balls placed at rotated positions but kept
    upright, as in the game, so a square never turns into a diamond."""
    cs = []
    place(canvas, tube_layer(W, balls, tube_fill=fill, draw_balls=False, centres=cs), cx, cy, shadow_dy, angle)
    t = math.radians(angle)
    for name, bx, by, D in cs:
        x = bx * math.cos(t) - by * math.sin(t)
        y = bx * math.sin(t) + by * math.cos(t)
        place(canvas, ball_layer(D, name, D / 40.0), cx + x, cy + y, 0)


def background(rgb, dots=False, dot_rgb=INK, dot_alpha=0.14):
    img = Image.new("RGBA", (N, N), rgb + (255,))
    if dots:
        ov = Image.new("RGBA", (N, N), (0, 0, 0, 0))
        d = ImageDraw.Draw(ov)
        sp, r = u(36), u(2.6)
        off = u(18)
        a = int(255 * dot_alpha)
        y = off
        while y < N:
            x = off
            while x < N:
                d.ellipse((x - r, y - r, x + r, y + r), fill=dot_rgb + (a,))
                x += sp
            y += sp
        img.alpha_composite(ov)
    return img


def finish(img, name):
    out = img.convert("RGB").resize((512, 512), Image.LANCZOS)
    path = os.path.join(OUT, name)
    out.save(path, optimize=True)
    return path


# ---------------------------------------------------------------- concepts

def concept_a():
    img = background(TOMATO, dots=True)
    W = u(110)
    k = W / 54
    gap = u(16)
    cy = u(250)
    tubes = [
        ["rose", "azure", "rose", "teal"],
        ["amber", "amber", "amber", "amber"],
        ["teal", "iris", "azure", "iris"],
    ]
    for i, balls in enumerate(tubes):
        cx = u(256) + (i - 1) * (W + gap)
        fill = (255, 248, 225) if i == 1 else WHITE  # sortedTubeFill
        place_tube(img, W, balls, cx, cy, 5 * k, fill=fill)
    return finish(img, "icon_A_512.png")


def quad(p0, p1, p2, t):
    return tuple((1 - t) ** 2 * a + 2 * (1 - t) * t * b + t * t * c for a, b, c in zip(p0, p1, p2))


def concept_b():
    img = background(BLUE, dots=True, dot_rgb=WHITE, dot_alpha=0.16)
    W = u(SRC_W)
    k = W / 54
    H = 186 * k
    D = 41 * k
    # destination: upright, right side, 3 amber waiting for the 4th
    dx, dtop = u(DX), u(DTOP)
    dcy = dtop + H / 2
    # source: tilted toward the destination
    ang = ANG
    scx, scy = u(SCX), u(SCY)
    half = H / 2
    a = math.radians(ang)
    mouth = (scx + math.sin(a) * (half - 0.1 * D), scy - math.cos(a) * (half - 0.1 * D))
    target = (dx, dtop + u(12))
    ctrl = (u(CTRLX), u(CTRLY))
    tb = TB
    ball_pos = quad(mouth, ctrl, target, tb)
    place_tube(img, W, ["rose", "teal", "azure"], scx, scy, 5 * k, angle=ang)
    place_tube(img, W, ["amber", "amber", "amber"], dx, dcy, 5 * k)
    # dashed flight path from the source mouth to the ball
    ov = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    dd = ImageDraw.Draw(ov)
    steps = 120
    pts = [quad(mouth, ctrl, target, tb * i / steps) for i in range(steps + 1)]
    dash_on = True
    seg = []
    acc = 0.0
    dash, gap_len = u(16), u(13)
    width = int(u(8))
    start_skip = u(22)
    walked = 0.0
    for p, q in zip(pts, pts[1:]):
        l = math.dist(p, q)
        walked += l
        if walked < start_skip:
            continue
        acc += l
        if dash_on:
            seg.append(q)
            if acc >= dash:
                if len(seg) > 1:
                    dd.line(seg, fill=WHITE + (255,), width=width, joint="curve")
                    for e in (seg[0], seg[-1]):
                        r = width / 2
                        dd.ellipse((e[0] - r, e[1] - r, e[0] + r, e[1] + r), fill=WHITE + (255,))
                seg, acc, dash_on = [], 0.0, False
        else:
            if acc >= gap_len:
                seg, acc, dash_on = [q], 0.0, True
    img.alpha_composite(ov)
    place(img, ball_layer(D, "amber", D / 40), ball_pos[0], ball_pos[1], 4 * k)
    return finish(img, "icon_B_512.png")


SRC_W, DX, DTOP, ANG, SCX, SCY, CTRLX, CTRLY, TB = 84, 374, 160, 46.0, 170, 294, 300, -26, 0.62


def concept_c():
    img = background(TOMATO, dots=True)
    W = u(118)
    k = W / 54
    place_tube(img, W, ["teal", "rose", "azure", "amber"], u(256), u(252), 6 * k, angle=12)
    return finish(img, "icon_C_512.png")


# ---------------------------------------------------------------- preview

def rounded(img, size):
    small = img.resize((size, size), Image.LANCZOS)
    m = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size * 4 - 1, size * 4 - 1), radius=size * 4 * 0.2, fill=255)
    m = m.resize((size, size), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(small, (0, 0), m)
    return out


def preview(control_path, paths):
    items = [("Control (current)", control_path)] + list(zip(["A: three tubes", "B: mid-pour", "C: single tube"], paths))
    try:
        font = ImageFont.truetype("arialbd.ttf", 26)
        small = ImageFont.truetype("arial.ttf", 18)
    except OSError:
        font = small = ImageFont.load_default()
    colw, gutter = 512, 40
    Wd = gutter + len(items) * (colw + gutter)
    Hd = 60 + 512 + 30 + 26 + 128 + 90 + 48 + 40
    sheet = Image.new("RGB", (Wd, Hd), WHITE)
    d = ImageDraw.Draw(sheet)
    for i, (label, p) in enumerate(items):
        im = Image.open(p).convert("RGB")
        x = gutter + i * (colw + gutter)
        d.text((x, 18), label, fill=INK, font=font)
        sheet.paste(im.resize((512, 512), Image.LANCZOS), (x, 60))
        y = 60 + 512 + 30
        d.text((x, y), "128 px", fill=(110, 105, 128), font=small)
        r = rounded(im, 128)
        sheet.paste(r, (x, y + 26), r)
        r64 = rounded(im, 64)
        sheet.paste(r64, (x + 160, y + 26), r64)
        d.text((x + 160, y + 96), "64", fill=(110, 105, 128), font=small)
        r48 = rounded(im, 48)
        sheet.paste(r48, (x + 250, y + 26), r48)
        d.text((x + 250, y + 80), "48", fill=(110, 105, 128), font=small)
    # search-results strip: all four at 48 in a row, as on Play
    y = Hd - 48 - 30
    d.text((gutter, y - 34), "Side by side at 48 px (search-result size)", fill=INK, font=small)
    for i, (label, p) in enumerate(items):
        r48 = rounded(Image.open(p).convert("RGB"), 48)
        sheet.paste(r48, (gutter + i * 80, y), r48)
    path = os.path.join(OUT, "preview_sheet.png")
    sheet.save(path, optimize=True)
    return path


if __name__ == "__main__":
    control = r"C:\Users\pranta\AppData\Local\Temp\claude\39713f3ccb207f61\aaafa977-eb0b-4412-9367-5b2009b99b28\scratchpad\artifact-files\3d0b5f5e-6bec-4f05-bdec-182b36b18093\project\pourfect-toybox\store\play_store_icon_512.png"
    ps = [concept_a(), concept_b(), concept_c()]
    print(preview(control, ps))
