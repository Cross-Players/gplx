"""Generate GPLX app icon SVGs (full, adaptive foreground, adaptive background)."""
import sys
from pathlib import Path

out = Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=True)

DEFS = """
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#6A84FF"/>
    <stop offset="0.55" stop-color="#3D5AFE"/>
    <stop offset="1" stop-color="#2A3EB1"/>
  </linearGradient>
  <radialGradient id="glow" cx="0.28" cy="0.22" r="0.6">
    <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.28"/>
    <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
  </radialGradient>
  <linearGradient id="badge" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#2EE0C4"/>
    <stop offset="1" stop-color="#00A88F"/>
  </linearGradient>
  <filter id="shadow" x="-30%" y="-30%" width="160%" height="160%">
    <feDropShadow dx="0" dy="14" stdDeviation="18" flood-color="#14205E" flood-opacity="0.35"/>
  </filter>
</defs>
"""

BACKGROUND = """
<rect width="1024" height="1024" fill="url(#bg)"/>
<rect width="1024" height="1024" fill="url(#glow)"/>
"""

# Steering wheel centred at (490, 490) with a "passed" check badge at bottom-right.
MARK = """
<g filter="url(#shadow)">
  <g fill="none" stroke="#FFFFFF" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="490" cy="490" r="236" stroke-width="66"/>
    <path d="M268 455 C 360 430, 420 430, 490 470 C 560 430, 620 430, 712 455" stroke-width="58"/>
    <path d="M490 500 L 490 700" stroke-width="58"/>
  </g>
  <circle cx="490" cy="488" r="70" fill="#FFFFFF"/>
  <circle cx="490" cy="488" r="26" fill="#3D5AFE"/>
  <circle cx="712" cy="712" r="134" fill="#FFFFFF"/>
  <circle cx="712" cy="712" r="110" fill="url(#badge)"/>
  <path d="M660 714 L 698 752 L 768 676" fill="none" stroke="#FFFFFF"
        stroke-width="38" stroke-linecap="round" stroke-linejoin="round"/>
</g>
"""


def svg(body: str) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" '
        f'viewBox="0 0 1024 1024">{DEFS}{body}</svg>'
    )


# Full-bleed icon (iOS / legacy Android): mark recentred and slightly shrunk.
(out / "icon.svg").write_text(svg(BACKGROUND + f'<g transform="translate(512 512) scale(0.92) translate(-520 -520)">{MARK}</g>'))
# Adaptive foreground: must sit inside the ~66% safe zone (radius ~338).
(out / "icon_foreground.svg").write_text(svg(f'<g transform="translate(512 512) scale(0.72) translate(-520 -520)">{MARK}</g>'))
(out / "icon_background.svg").write_text(svg(BACKGROUND))
