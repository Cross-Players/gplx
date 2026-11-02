"""Compose App Store marketing images from raw simulator screenshots.

Usage: python3 screenshots/compose.py   (run from the repo root)
Writes HTML into screenshots/build/ and renders PNGs into screenshots/store/.
"""
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
BUILD = ROOT / "build"
STORE = ROOT / "store"
ICON = ROOT.parent / "assets" / "icon" / "icon.png"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

CAPTIONS = [
    ("01_home", "Ôn thi GPLX", "dễ dàng mỗi ngày", "Mọi thứ bạn cần trong một ứng dụng"),
    ("02_test_sets", "Thi thử theo", "bộ đề chính thức", "Lưu kết quả, biết ngay Đạt hay Trượt"),
    ("03_quiz", "Làm bài", "như thi thật", "Bấm giờ, chấm điểm tức thì"),
    ("04_chapters", "Ôn tập câu hỏi", "theo từng chương", "Kèm danh sách câu điểm liệt"),
    ("05_signs", "Tra cứu", "biển báo giao thông", "Cấm, nguy hiểm, hiệu lệnh, chỉ dẫn, phụ"),
    ("06_tips", "Mẹo ghi nhớ", "học nhanh, nhớ lâu", "Tổng hợp mẹo hay gặp trong đề thi"),
]

BASE_CSS = """
@import url('https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@500;700;800&display=block');
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { width: {W}px; height: {H}px; overflow: hidden; }
body {
  font-family: 'Be Vietnam Pro', -apple-system, sans-serif;
  color: #fff;
  background:
    radial-gradient(circle at 18% 12%, rgba(255,255,255,.22), transparent 45%),
    radial-gradient(circle at 90% 85%, rgba(0,194,168,.35), transparent 40%),
    linear-gradient(150deg, #6A84FF 0%, #3D5AFE 50%, #2A3EB1 100%);
  position: relative;
}
.device {
  position: absolute; background: #0F172A;
  box-shadow: 0 {S1}px {S2}px rgba(10,20,70,.45);
}
.device img { display: block; width: 100%; }
"""


def render(html: str, name: str, w: int, h: int, out_dir: Path) -> None:
    BUILD.mkdir(parents=True, exist_ok=True)
    out_dir.mkdir(parents=True, exist_ok=True)
    src = BUILD / f"{out_dir.name}_{name}.html"
    src.write_text(html)
    subprocess.run(
        [CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
         "--force-device-scale-factor=1", "--virtual-time-budget=8000",
         f"--window-size={w},{h}", f"--screenshot={out_dir / (name + '.png')}",
         src.as_uri()],
        check=True, capture_output=True,
    )


def css(w: int, h: int) -> str:
    return (BASE_CSS.replace("{W}", str(w)).replace("{H}", str(h))
            .replace("{S1}", str(round(w * .02))).replace("{S2}", str(round(w * .05))))


def portrait(device: str, w: int, h: int, dev_w: float, top: float,
             bezel: float, radius: float) -> None:
    """dev_w/top/bezel/radius are fractions of the canvas width."""
    out = STORE / device
    for shot, line1, line2, sub in CAPTIONS:
        dw = round(w * dev_w)
        html = f"""<!doctype html><meta charset="utf-8"><style>{css(w, h)}
.head {{ position: absolute; top: {round(w * .09)}px; left: 0; right: 0; text-align: center; }}
.head h1 {{ font-weight: 800; font-size: {round(w * .085)}px; line-height: 1.15; letter-spacing: -.01em; }}
.head h1 span {{ color: #7CF5DF; }}
.head p {{ margin-top: {round(w * .025)}px; font-weight: 500; font-size: {round(w * .038)}px; opacity: .9; }}
.device {{ left: {(w - dw) // 2}px; top: {round(w * top)}px; width: {dw}px;
  padding: {round(w * bezel)}px; border-radius: {round(w * (radius + bezel))}px; }}
.device img {{ border-radius: {round(w * radius)}px; }}
</style>
<div class="head"><h1>{line1}<br><span>{line2}</span></h1><p>{sub}</p></div>
<div class="device"><img src="{(RAW / device_raw[device] / (shot + '.png')).as_uri()}"></div>"""
        render(html, shot, w, h, out)


def banner(name: str, w: int, h: int) -> None:
    """Landscape header / search-result artwork: title on the left, phones on the right."""
    u = h / 100  # 1% of height
    phones = [("01_home", -1), ("05_signs", 1), ("03_quiz", 0)]  # centre phone last = on top
    ph_w = round(min(u * 38, w * .17))
    ph_h = ph_w * 2622 / 1206
    cx = w * .74
    t = min(u, w / 190)  # type unit, so the title never runs into the phones
    devices = ""
    for shot, pos in phones:
        x = round(cx + pos * ph_w * .78 - ph_w / 2)
        y = round((h - ph_h) / 2 + (0 if pos == 0 else u * 8))
        scale = 1 if pos == 0 else .9
        devices += (
            f'<div class="device" style="left:{x}px;top:{y}px;width:{ph_w}px;'
            f'transform:scale({scale}) rotate({pos * 6}deg);z-index:{2 - abs(pos)}">'
            f'<img src="{(RAW / "iphone" / (shot + ".png")).as_uri()}"></div>')
    html = f"""<!doctype html><meta charset="utf-8"><style>{css(w, h)}
.device {{ padding: {round(ph_w * .03)}px; border-radius: {round(ph_w * .17)}px;
  box-shadow: 0 {round(u * 2)}px {round(u * 6)}px rgba(10,20,70,.5); }}
.device img {{ border-radius: {round(ph_w * .14)}px; }}
.title {{ position: absolute; left: {round(w * .08)}px; top: 50%; transform: translateY(-50%);
  width: {round(w * .42)}px; }}
.title img {{ width: {round(t * 18)}px; border-radius: {round(t * 4.2)}px;
  box-shadow: 0 {round(u)}px {round(u * 3)}px rgba(10,20,70,.4); }}
.title h1 {{ margin-top: {round(t * 5)}px; font-weight: 800; font-size: {round(t * 9)}px;
  line-height: 1.08; letter-spacing: -.015em; }}
.title h1 span {{ color: #7CF5DF; }}
.title p {{ margin-top: {round(t * 3.5)}px; font-weight: 500; font-size: {round(t * 3.6)}px; opacity: .9; }}
</style>
<div class="title"><img src="{ICON.as_uri()}">
<h1>Luyện thi GPLX<br><span>đậu ngay lần đầu</span></h1>
<p>Bộ đề chính thức · Biển báo · Mẹo ghi nhớ</p></div>
{devices}"""
    render(html, name, w, h, STORE / "header")


device_raw = {"iphone_6.3": "iphone", "ipad_13": "ipad"}

if __name__ == "__main__":
    portrait("iphone_6.3", 1206, 2622, dev_w=.80, top=.56, bezel=.022, radius=.13)
    portrait("ipad_13", 2064, 2752, dev_w=.80, top=.40, bezel=.016, radius=.035)
    banner("header_5244x2950", 5244, 2950)
    banner("search_3840x1646", 3840, 1646)
