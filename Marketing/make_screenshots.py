#!/usr/bin/env python3
"""
Generates professional App Store screenshots for ToneVault at 1290x2796
(iPhone 6.7"/6.9"). Pure PIL — no simulator needed. Run:  python3 make_screenshots.py
Outputs into ./screenshots/.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, os

W, H = 1290, 2796
LATO = "/usr/share/fonts/truetype/lato/"
OUT = os.path.join(os.path.dirname(__file__), "screenshots")
os.makedirs(OUT, exist_ok=True)

ACCENT = (225, 84, 56)
INK = (24, 26, 30)
CARD = (255, 255, 255)
SUBTLE = (142, 148, 158)
BG_DARK1 = (30, 33, 39)
BG_DARK2 = (16, 17, 20)

def font(name, size):
    return ImageFont.truetype(LATO + name, size)

F_HEAD = lambda s: font("Lato-Black.ttf", s)
F_BOLD = lambda s: font("Lato-Bold.ttf", s)
F_SEMI = lambda s: font("Lato-Semibold.ttf", s)
F_REG  = lambda s: font("Lato-Regular.ttf", s)
F_MED  = lambda s: font("Lato-Medium.ttf", s)

def rounded(draw, box, r, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)

def vgradient(size, top, bot):
    img = Image.new("RGB", size, top)
    d = ImageDraw.Draw(img)
    for y in range(size[1]):
        t = y / size[1]
        d.line([(0, y), (size[0], y)],
               fill=tuple(int(top[i]*(1-t)+bot[i]*t) for i in range(3)))
    return img

def text_center(d, cx, y, s, fnt, fill):
    w = d.textlength(s, font=fnt)
    d.text((cx - w/2, y), s, font=fnt, fill=fill)
    return w

def wrap_center(d, cx, y, text, fnt, fill, max_w, leading=8):
    words = text.split()
    lines, cur = [], ""
    for w in words:
        test = (cur + " " + w).strip()
        if d.textlength(test, font=fnt) <= max_w:
            cur = test
        else:
            lines.append(cur); cur = w
    if cur: lines.append(cur)
    asc, desc = fnt.getmetrics()
    lh = asc + desc + leading
    for i, ln in enumerate(lines):
        text_center(d, cx, y + i*lh, ln, fnt, fill)
    return y + len(lines)*lh

# ---------- knob drawing ----------
def draw_knob(img, cx, cy, r, frac, accent=ACCENT, label=None, value=None, d=None):
    d = d or ImageDraw.Draw(img)
    track_r = r + 14
    bbox = [cx-track_r, cy-track_r, cx+track_r, cy+track_r]
    d.arc(bbox, start=135, end=405, fill=(210, 214, 220), width=10)
    d.arc(bbox, start=135, end=135+frac*270, fill=accent, width=10)
    # metallic body
    knob = Image.new("RGB", (r*2, r*2), (0,0,0))
    kd = ImageDraw.Draw(knob)
    for i in range(r, 0, -1):
        t = i/r
        c = int(225*(1-t)+150*t)
        kd.ellipse([r-i, r-i, r+i, r+i], fill=(c, c+3, c+7))
    mask = Image.new("L", (r*2, r*2), 0)
    ImageDraw.Draw(mask).ellipse([0,0,r*2,r*2], fill=255)
    img.paste(knob, (cx-r, cy-r), mask)
    d.ellipse([cx-r, cy-r, cx+r, cy+r], outline=(205,208,214), width=2)
    ang = 135 + frac*270
    rad = ang*math.pi/180
    x2 = cx + math.cos(rad)*(r-10); y2 = cy + math.sin(rad)*(r-10)
    d.line([(cx, cy), (x2, y2)], fill=accent, width=6)
    if label:
        text_center(d, cx, cy+r+22, label, F_SEMI(30), INK)
    if value:
        text_center(d, cx, cy+r+58, value, F_MED(26), SUBTLE)

def draw_fader(img, cx, top, height, frac, label, d=None):
    d = d or ImageDraw.Draw(img)
    rounded(d, [cx-4, top, cx+4, top+height], 4, (214,217,223))
    fill_h = int(height*frac)
    rounded(d, [cx-4, top+height-fill_h, cx+4, top+height], 4, ACCENT)
    cap_y = top + height - fill_h - 12
    rounded(d, [cx-26, cap_y, cx+26, cap_y+24], 6, (236,238,242), outline=(200,203,209), width=2)
    text_center(d, cx, top+height+14, label, F_MED(24), SUBTLE)

# ---------- small drawn icons (avoid missing-glyph tofu) ----------
def icon_photo(d, x, y, s, col):
    d.rounded_rectangle([x, y, x+s, y+int(s*0.8)], radius=6, outline=col, width=4)
    d.ellipse([x+int(s*0.2), y+int(s*0.28), x+int(s*0.44), y+int(s*0.52)], outline=col, width=4)
    d.line([(x+4, y+int(s*0.72)), (x+int(s*0.5), y+int(s*0.4)), (x+s-4, y+int(s*0.72))], fill=col, width=4)

def icon_mic(d, x, y, s, col):
    d.rounded_rectangle([x+int(s*0.32), y, x+int(s*0.68), y+int(s*0.55)], radius=int(s*0.18), fill=col)
    d.arc([x+int(s*0.18), y+int(s*0.2), x+int(s*0.82), y+int(s*0.75)], start=20, end=160, fill=col, width=4)
    d.line([(x+int(s*0.5), y+int(s*0.72)), (x+int(s*0.5), y+s)], fill=col, width=4)
    d.line([(x+int(s*0.3), y+s), (x+int(s*0.7), y+s)], fill=col, width=4)

def icon_arrow(d, x, y, s, col, up=True):
    cx = x + s//2
    if up:
        d.line([(cx, y+s), (cx, y)], fill=col, width=5)
        d.line([(cx-int(s*0.28), y+int(s*0.3)), (cx, y), (cx+int(s*0.28), y+int(s*0.3))], fill=col, width=5)
    else:
        d.line([(cx, y), (cx, y+s)], fill=col, width=5)
        d.line([(cx-int(s*0.28), y+int(s*0.7)), (cx, y+s), (cx+int(s*0.28), y+int(s*0.7))], fill=col, width=5)

def bullet(d, cx, cy, r, col):
    d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=col)

# ---------- phone frame ----------
PHONE_W = 1020
PHONE_X = (W - PHONE_W)//2
PHONE_TOP = 596
PHONE_H = H - PHONE_TOP - 60
SCREEN_R = 82

def phone(base, screen_img):
    d = ImageDraw.Draw(base)
    # shadow
    sh = Image.new("RGBA", base.size, (0,0,0,0))
    ImageDraw.Draw(sh).rounded_rectangle(
        [PHONE_X-14, PHONE_TOP-14, PHONE_X+PHONE_W+14, PHONE_TOP+PHONE_H+14],
        radius=SCREEN_R+14, fill=(0,0,0,120))
    sh = sh.filter(ImageFilter.GaussianBlur(28))
    base.alpha_composite(sh)
    # body
    ImageDraw.Draw(base).rounded_rectangle(
        [PHONE_X-16, PHONE_TOP-16, PHONE_X+PHONE_W+16, PHONE_TOP+PHONE_H+16],
        radius=SCREEN_R+16, fill=(8,9,11,255))
    # screen
    mask = Image.new("L", (PHONE_W, PHONE_H), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0,0,PHONE_W,PHONE_H], radius=SCREEN_R, fill=255)
    base.paste(screen_img.convert("RGB"), (PHONE_X, PHONE_TOP), mask)

def new_screen(bg=(247,248,250)):
    s = Image.new("RGB", (PHONE_W, PHONE_H), bg)
    return s, ImageDraw.Draw(s)

def status_bar(d, dark=False):
    col = (255,255,255) if dark else INK
    d.text((60, 40), "9:41", font=F_BOLD(34), fill=col)
    # signal/battery hint
    d.rounded_rectangle([PHONE_W-120, 46, PHONE_W-70, 70], radius=6, outline=col, width=3)
    d.rounded_rectangle([PHONE_W-66, 52, PHONE_W-60, 64], radius=2, fill=col)

def nav_title(d, title, dark=False):
    col = (255,255,255) if dark else INK
    d.text((60, 120), title, font=F_HEAD(64), fill=col)

def tab_bar(d, active, dark=False):
    y = PHONE_H - 150
    bar_bg = (22,24,28) if dark else (252,252,253)
    d.rectangle([0, y, PHONE_W, PHONE_H], fill=bar_bg)
    d.line([(0,y),(PHONE_W,y)], fill=(60,64,70) if dark else (226,228,232), width=2)
    items = ["Library","Songs","Setlists","Settings"]
    step = PHONE_W/len(items)
    for i, it in enumerate(items):
        cx = int(step*i + step/2)
        col = ACCENT if i==active else (SUBTLE if not dark else (120,124,132))
        d.ellipse([cx-16, y+34, cx+16, y+66], outline=col, width=5)
        text_center(d, cx, y+80, it, F_MED(24), col)

# ================= COMPOSERS =================

def caption(base, headline, sub):
    d = ImageDraw.Draw(base)
    y = wrap_center(d, W//2, 120, headline, F_HEAD(84), (255,255,255), W-150, leading=2)
    wrap_center(d, W//2, y+18, sub, F_MED(42), (196,200,208), W-260, leading=6)

def screen_library():
    s, d = new_screen()
    status_bar(d); nav_title(d, "ToneVault")
    # recall last used card
    y = 230
    rounded(d, [50, y, PHONE_W-50, y+150], 28, CARD, outline=(233,235,239), width=2)
    d.text((80, y+28), "RECALL LAST USED", font=F_BOLD(24), fill=ACCENT)
    d.text((80, y+66), "Solo boost", font=F_BOLD(40), fill=INK)
    d.text((80, y+112), "Orange Drive Box", font=F_REG(30), fill=SUBTLE)
    draw_knob(s, PHONE_W-150, y+75, 40, 0.72, d=d)
    # gear list
    y += 200
    d.text((70, y), "GEAR", font=F_BOLD(26), fill=SUBTLE); y += 50
    gear = [("Orange Drive Box","Pedal · 3-Knob · 4 tones",(224,138,46)),
            ("Studio Combo","Amp · Amp Head · 3 tones",(58,114,224)),
            ("Blue Verb","Pedal · 4-Knob · 2 tones",(47,166,154)),
            ("Graphic EQ","Pedal · EQ 10 · 1 tone",(122,84,224))]
    for name, meta, col in gear:
        rounded(d, [50, y, PHONE_W-50, y+128], 24, CARD, outline=(233,235,239), width=2)
        rounded(d, [80, y+28, 152, y+100], 16, col)
        d.text((188, y+30), name, font=F_BOLD(36), fill=INK)
        d.text((188, y+80), meta, font=F_REG(28), fill=SUBTLE)
        y += 150
    tab_bar(d, 0)
    return s

def screen_knobs():
    s, d = new_screen()
    status_bar(d)
    d.text((60, 110), "New Tone", font=F_HEAD(58), fill=INK)
    d.text((PHONE_W-230, 128), "Save", font=F_BOLD(38), fill=ACCENT)
    # name field
    y = 220
    rounded(d, [50, y, PHONE_W-50, y+86], 20, CARD, outline=(226,228,232), width=2)
    d.text((80, y+24), "Verse tone", font=F_MED(38), fill=INK)
    y += 130
    d.text((70, y), "SET THE CONTROLS", font=F_BOLD(26), fill=SUBTLE)
    d.text((70, y+40), "Drag each knob to match your hardware.", font=F_REG(28), fill=SUBTLE)
    y += 120
    knobs = [("Drive",0.35),("Tone",0.62),("Level",0.78)]
    xs = [PHONE_W*0.24, PHONE_W*0.5, PHONE_W*0.76]
    for (lab, fr), x in zip(knobs, xs):
        draw_knob(s, int(x), y+80, 78, fr, label=lab,
                  value=f"{round(fr*10,1)}", d=d)
    # attachments row
    y += 340
    d.text((70, y-56), "ATTACHMENTS", font=F_BOLD(26), fill=SUBTLE)
    bw = (PHONE_W-120)//2
    for i, (draw_icon, lab) in enumerate([(icon_photo,"Photo"),(icon_mic,"Record clip")]):
        bx = 50 + i*(bw + 20)
        rounded(d, [bx, y, bx+bw, y+96], 18, (245,246,248), outline=(226,228,232), width=2)
        draw_icon(d, bx+30, y+28, 42, ACCENT)
        d.text((bx+96, y+28), lab, font=F_MED(32), fill=INK)
    # notes field to fill space
    y += 140
    d.text((70, y), "NOTES", font=F_BOLD(26), fill=SUBTLE)
    rounded(d, [50, y+42, PHONE_W-50, y+170], 20, (245,246,248), outline=(226,228,232), width=2)
    d.text((80, y+66), "Bridge pickup, amp on the edge of breakup.", font=F_REG(30), fill=SUBTLE)
    return s

def screen_song():
    s, d = new_screen()
    status_bar(d)
    d.text((60, 110), "Midnight Run", font=F_HEAD(56), fill=INK)
    d.text((64, 186), "The Locals · 3 tones", font=F_REG(30), fill=SUBTLE)
    y = 270
    d.text((70, y), "RIG FOR THIS SONG", font=F_BOLD(26), fill=SUBTLE); y += 56
    rig = [("Orange Drive Box","Verse tone","Drive 3.5   Tone 6   Level 7"),
           ("Studio Combo","Clean rhythm","Gain 4  Bass 6  Mid 5  Treble 6  Master 4"),
           ("Blue Verb","Wash","Mix 6   Decay 7   Tone 5   Level 6")]
    for gear, tone, ctrl in rig:
        rounded(d, [50, y, PHONE_W-50, y+150], 24, CARD, outline=(233,235,239), width=2)
        d.text((80, y+24), gear, font=F_BOLD(36), fill=INK)
        tw = d.textlength(tone, font=F_MED(30))
        d.text((PHONE_W-80-tw, y+30), tone, font=F_MED(30), fill=SUBTLE)
        d.text((80, y+84), ctrl, font=F_MED(30), fill=ACCENT)
        y += 172
    tab_bar(d, 1)
    return s

def screen_stage():
    s, d = new_screen(bg=(14,15,18))
    status_bar(d, dark=True)
    d.text((60, 120), "#4", font=F_BOLD(48), fill=ACCENT)
    d.text((60, 190), "Midnight Run", font=F_HEAD(78), fill=(255,255,255))
    d.text((64, 292), "The Locals", font=F_MED(40), fill=(150,154,162))
    y = 380
    blocks = [("Orange Drive Box","Verse tone",[("Drive","3.5"),("Tone","6"),("Level","7")]),
              ("Studio Combo","Clean",[("Gain","4"),("Bass","6"),("Mid","5"),("Master","4")])]
    for gear, tone, ctrls in blocks:
        bh = 90 + len(ctrls)*70
        rounded(d, [50, y, PHONE_W-50, y+bh], 26, (28,30,36))
        d.text((84, y+28), gear, font=F_BOLD(44), fill=(255,255,255))
        tw = d.textlength(tone, font=F_MED(34))
        d.text((PHONE_W-84-tw, y+38), tone, font=F_MED(34), fill=(150,154,162))
        yy = y+96
        for lab, val in ctrls:
            d.text((84, yy), lab, font=F_MED(38), fill=(220,222,226))
            vw = d.textlength(val, font=F_BOLD(40))
            d.text((PHONE_W-84-vw, yy-2), val, font=F_BOLD(40), fill=ACCENT)
            yy += 70
        y += bh + 30
    return s

def screen_data():
    s, d = new_screen()
    status_bar(d); nav_title(d, "Settings")
    y = 250
    # pro row
    rounded(d, [50, y, PHONE_W-50, y+110], 22, CARD, outline=(233,235,239), width=2)
    d.text((80, y+34), "✓ ToneVault Pro — unlocked", font=F_BOLD(34), fill=(46,160,90))
    y += 150
    d.text((70, y), "YOUR DATA", font=F_BOLD(26), fill=SUBTLE); y += 54
    for up, lab in [(True,"Back up everything"),(False,"Restore from backup")]:
        rounded(d, [50, y, PHONE_W-50, y+96], 20, CARD, outline=(233,235,239), width=2)
        icon_arrow(d, 84, y+26, 44, ACCENT, up=up)
        d.text((156, y+26), lab, font=F_MED(36), fill=INK)
        y += 116
    y += 6
    rounded(d, [50, y, PHONE_W-50, y+170], 22, (250,244,242), outline=(240,220,214), width=2)
    wrap_left(d, 84, y+28, "Your tones are yours — export anytime to Files, iCloud Drive, or email. No account, no cloud.",
              F_MED(31), (120,70,58), PHONE_W-180)
    tab_bar(d, 3)
    return s

def wrap_left(d, x, y, text, fnt, fill, max_w, leading=8):
    words = text.split(); lines, cur = [], ""
    for w in words:
        test = (cur+" "+w).strip()
        if d.textlength(test, font=fnt) <= max_w: cur = test
        else: lines.append(cur); cur = w
    if cur: lines.append(cur)
    asc, desc = fnt.getmetrics(); lh = asc+desc+leading
    for i, ln in enumerate(lines):
        d.text((x, y+i*lh), ln, font=fnt, fill=fill)
    return y + len(lines)*lh

def screen_paywall():
    s, d = new_screen()
    status_bar(d)
    draw_knob(s, PHONE_W//2, 230, 72, 0.8, d=d)
    text_center(d, PHONE_W//2, 340, "ToneVault Pro", F_HEAD(58), INK)
    y = wrap_center(d, PHONE_W//2, 420, "Everything unlocked with one purchase.",
                    F_MED(34), SUBTLE, PHONE_W-160)
    y += 24
    for txt in ["Unlimited gear, tones & setlists",
                "Attach audio clips of your tones",
                "Export printable PDF cheat-sheets",
                "One-time unlock — yours forever"]:
        rounded(d, [60, y, PHONE_W-60, y+96], 18, (247,248,250), outline=(233,235,239), width=2)
        bullet(d, 104, y+48, 12, ACCENT)
        d.text((150, y+26), txt, font=F_MED(33), fill=INK)
        y += 116
    y += 10
    rounded(d, [60, y, PHONE_W-60, y+108], 24, ACCENT)
    text_center(d, PHONE_W//2, y+28, "Unlock Pro", F_BOLD(44), (255,255,255))
    y += 140
    text_center(d, PHONE_W//2, y, "Back up and export your tones anytime.", F_MED(28), SUBTLE)
    return s

SHOTS = [
    ("01_library.png", "Every tone, instantly recalled",
     "Save the exact knob positions of your pedals and amps.", screen_library),
    ("02_knobs.png", "Drag the knobs. No camera scanning.",
     "Build your gear by hand and match your real settings.", screen_knobs),
    ("03_song.png", "Your whole rig for a song",
     "Group every pedal and amp setting a song needs.", screen_song),
    ("04_stage.png", "Stage-ready in dark venues",
     "Big, high-contrast settings you can read mid-set.", screen_stage),
    ("05_data.png", "No account. No cloud.",
     "100% offline. Back up and own your data forever.", screen_data),
    ("06_pro.png", "Unlock the full vault",
     "One purchase unlocks everything.", screen_paywall),
]

for fname, head, sub, fn in SHOTS:
    base = vgradient((W, H), BG_DARK1, BG_DARK2).convert("RGBA")
    caption(base, head, sub)
    screen = fn()
    phone(base, screen)
    base.convert("RGB").save(os.path.join(OUT, fname), "PNG")
    print("wrote", fname)

print("done ->", OUT)
