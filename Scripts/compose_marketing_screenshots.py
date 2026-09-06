#!/usr/bin/env python3
"""
Compose connected App Store marketing screenshots from raw simulator captures.

Each frame shares the same layout, type system, and a continuous gold/navy
band that shifts across the series — so swiping the App Store carousel reads
as one story.
"""

from __future__ import annotations

import math
import sys
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# App Store Connect 6.7" portrait
CANVAS_W = 1284
CANVAS_H = 2778

CREAM = (247, 241, 221)
NAVY = (2, 4, 85)
NAVY_SOFT = (25, 51, 82)
GOLD = (196, 163, 90)
GOLD_SOFT = (212, 186, 126)
MUTED = (107, 101, 96)
WHITE = (255, 255, 255)


@dataclass(frozen=True)
class Slide:
    source: str
    output: str
    index: int
    total: int
    eyebrow: str
    headline: str
    support: str


SLIDES = [
    Slide(
        source="01-order.png",
        output="01-real-food.png",
        index=0,
        total=5,
        eyebrow="HAMPTONS BURGERS",
        headline="Real food.",
        support="Locally sourced. Seed oil free.\nCooked in beef tallow.",
    ),
    Slide(
        source="02-rewards.png",
        output="02-then-earn.png",
        index=1,
        total=5,
        eyebrow="THEN REWARDS",
        headline="Then earn.",
        support="Points on every visit.\nRedeem burgers & more in store.",
    ),
    Slide(
        source="03-find-us.png",
        output="03-come-visit.png",
        index=2,
        total=5,
        eyebrow="GYPSUM, COLORADO",
        headline="Come visit.",
        support="Map, hours, and how to reach us —\nall in one place.",
    ),
    Slide(
        source="04-faq.png",
        output="04-ask-away.png",
        index=3,
        total=5,
        eyebrow="GOOD TO KNOW",
        headline="Ask away.",
        support="Straight answers about how we\ncook, serve, and show up.",
    ),
    Slide(
        source="05-account.png",
        output="05-make-it-yours.png",
        index=4,
        total=5,
        eyebrow="YOUR PROFILE",
        headline="Make it yours.",
        support="Name, points, and rewards —\nsaved to your account.",
    ),
]


def load_fonts() -> dict[str, ImageFont.FreeTypeFont]:
    bodoni = "/System/Library/Fonts/Supplemental/Bodoni 72.ttc"
    avenir = "/System/Library/Fonts/Avenir Next.ttc"
    # Bodoni index 2 = Bold; Avenir Next 2 = Demi Bold, 5 = Medium, 7 = Regular
    return {
        "headline": ImageFont.truetype(bodoni, size=118, index=2),
        "eyebrow": ImageFont.truetype(avenir, size=28, index=2),
        "support": ImageFont.truetype(avenir, size=36, index=5),
        "index": ImageFont.truetype(avenir, size=24, index=7),
    }


def hex_rgb(r: int, g: int, b: int, a: int = 255) -> tuple[int, int, int, int]:
    return (r, g, b, a)


def draw_connected_background(index: int, total: int) -> Image.Image:
    """Shared cream field + a gold band that travels across the series."""
    img = Image.new("RGBA", (CANVAS_W, CANVAS_H), CREAM + (255,))
    overlay = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Soft navy wash that drifts left → right across slides
    wash_cx = int((-0.15 + (index / max(total - 1, 1)) * 1.3) * CANVAS_W)
    wash_cy = int(CANVAS_H * 0.72)
    for radius, alpha in ((980, 28), (720, 36), (460, 22)):
        bbox = [
            wash_cx - radius,
            wash_cy - radius,
            wash_cx + radius,
            wash_cy + radius,
        ]
        draw.ellipse(bbox, fill=NAVY + (alpha,))

    # Continuous gold ribbon — same geometry, shifted by slide index
    ribbon = Image.new("RGBA", (CANVAS_W * 3, CANVAS_H), (0, 0, 0, 0))
    rdraw = ImageDraw.Draw(ribbon)
    y0 = int(CANVAS_H * 0.18)
    amplitude = 42
    thickness = 10
    points_top = []
    points_bot = []
    for x in range(0, CANVAS_W * 3, 8):
        y = y0 + int(math.sin(x / 220.0) * amplitude)
        points_top.append((x, y - thickness // 2))
        points_bot.append((x, y + thickness // 2))
    poly = points_top + list(reversed(points_bot))
    rdraw.polygon(poly, fill=GOLD + (210,))

    # Soft second ribbon underneath for depth
    points_top2 = [(x, y + 28) for x, y in points_top]
    points_bot2 = [(x, y + 28) for x, y in points_bot]
    poly2 = points_top2 + list(reversed(points_bot2))
    rdraw.polygon(poly2, fill=GOLD_SOFT + (70,))

    shift = int((index / max(total - 1, 1)) * CANVAS_W)
    cropped = ribbon.crop((shift, 0, shift + CANVAS_W, CANVAS_H))
    overlay = Image.alpha_composite(overlay, cropped)

    # Thin navy rule under the type zone (same Y on every slide)
    rule_y = int(CANVAS_H * 0.235)
    draw = ImageDraw.Draw(overlay)
    draw.rounded_rectangle(
        [96, rule_y, CANVAS_W - 96, rule_y + 3],
        radius=2,
        fill=NAVY + (40,),
    )

    return Image.alpha_composite(img, overlay)


def rounded_device_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return mask


def frame_phone(screenshot: Image.Image) -> Image.Image:
    """Wrap a simulator screenshot in a navy/gold device bezel."""
    bezel = 18
    radius = 92
    inner_radius = 78
    screen = screenshot.convert("RGBA")
    phone_w = screen.width + bezel * 2
    phone_h = screen.height + bezel * 2

    phone = Image.new("RGBA", (phone_w, phone_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(phone)

    # Outer navy chassis
    draw.rounded_rectangle(
        [0, 0, phone_w - 1, phone_h - 1],
        radius=radius,
        fill=NAVY + (255,),
    )
    # Gold hairline
    inset = 5
    draw.rounded_rectangle(
        [inset, inset, phone_w - 1 - inset, phone_h - 1 - inset],
        radius=radius - 4,
        outline=GOLD + (255,),
        width=3,
    )
    # Inner cream lip
    lip = 10
    draw.rounded_rectangle(
        [lip, lip, phone_w - 1 - lip, phone_h - 1 - lip],
        radius=radius - 8,
        fill=CREAM + (255,),
    )

    screen_mask = rounded_device_mask(screen.size, inner_radius)
    phone.paste(screen, (bezel, bezel), screen_mask)
    return phone


def drop_shadow(device: Image.Image, blur: int = 42, offset: tuple[int, int] = (0, 28)) -> Image.Image:
    shadow = Image.new("RGBA", device.size, (0, 0, 0, 0))
    alpha = device.split()[-1]
    shadow_layer = Image.new("RGBA", device.size, NAVY + (70,))
    shadow_layer.putalpha(alpha.point(lambda a: int(a * 0.55)))
    shadow = Image.alpha_composite(shadow, shadow_layer)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))

    canvas = Image.new(
        "RGBA",
        (device.width + abs(offset[0]) + blur * 2, device.height + abs(offset[1]) + blur * 2),
        (0, 0, 0, 0),
    )
    ox = blur + max(offset[0], 0)
    oy = blur + max(offset[1], 0)
    canvas.paste(shadow, (ox + offset[0], oy + offset[1]), shadow)
    canvas.paste(device, (ox, oy), device)
    return canvas


def fit_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.FreeTypeFont,
    max_width: int,
) -> ImageFont.FreeTypeFont:
    """Shrink font until text fits max_width."""
    size = font.size
    path = font.path
    index = getattr(font, "index", 0) or 0
    while size > 48:
        candidate = ImageFont.truetype(path, size=size, index=index)
        bbox = draw.textbbox((0, 0), text, font=candidate)
        if bbox[2] - bbox[0] <= max_width:
            return candidate
        size -= 4
    return ImageFont.truetype(path, size=size, index=index)


def draw_progress_dots(draw: ImageDraw.ImageDraw, index: int, total: int, y: int) -> None:
    spacing = 28
    radius = 7
    width = (total - 1) * spacing
    start_x = (CANVAS_W - width) // 2
    for i in range(total):
        x = start_x + i * spacing
        if i == index:
            draw.ellipse([x - radius - 2, y - radius - 2, x + radius + 2, y + radius + 2], fill=GOLD + (255,))
            draw.ellipse([x - radius + 1, y - radius + 1, x + radius - 1, y + radius - 1], fill=NAVY + (255,))
        else:
            draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=NAVY + (55,))


def compose_slide(raw_dir: Path, out_dir: Path, fonts: dict[str, ImageFont.FreeTypeFont], slide: Slide) -> Path:
    bg = draw_connected_background(slide.index, slide.total)
    draw = ImageDraw.Draw(bg)

    # Eyebrow + index
    eyebrow_y = 118
    draw.text((96, eyebrow_y), slide.eyebrow, font=fonts["eyebrow"], fill=GOLD + (255,))
    index_label = f"{slide.index + 1:02d} / {slide.total:02d}"
    index_bbox = draw.textbbox((0, 0), index_label, font=fonts["index"])
    draw.text(
        (CANVAS_W - 96 - (index_bbox[2] - index_bbox[0]), eyebrow_y + 4),
        index_label,
        font=fonts["index"],
        fill=MUTED + (255,),
    )

    # Headline
    headline_font = fit_text(draw, slide.headline, fonts["headline"], CANVAS_W - 192)
    draw.text((96, 178), slide.headline, font=headline_font, fill=NAVY + (255,))

    # Support copy
    support_y = 330
    for i, line in enumerate(slide.support.split("\n")):
        draw.text((96, support_y + i * 46), line, font=fonts["support"], fill=NAVY_SOFT + (255,))

    # Phone
    shot = Image.open(raw_dir / slide.source).convert("RGBA")
    # Scale phone so type, device, and progress dots all fit without clipping
    target_phone_h = int(CANVAS_H * 0.62)
    scale = target_phone_h / shot.height
    scaled = shot.resize((int(shot.width * scale), int(shot.height * scale)), Image.Resampling.LANCZOS)
    device = frame_phone(scaled)
    shadowed = drop_shadow(device)

    phone_x = (CANVAS_W - shadowed.width) // 2
    phone_y = int(CANVAS_H * 0.285)
    bg.paste(shadowed, (phone_x, phone_y), shadowed)

    # Progress dots in clear space under the phone
    draw = ImageDraw.Draw(bg)
    dots_y = phone_y + shadowed.height - 18
    if dots_y > CANVAS_H - 70:
        dots_y = CANVAS_H - 70
    draw_progress_dots(draw, slide.index, slide.total, dots_y)

    out_path = out_dir / slide.output
    bg.convert("RGB").save(out_path, "PNG", optimize=True)
    return out_path


def stitch_panorama(out_dir: Path, paths: list[Path]) -> Path:
    """Horizontal strip so you can preview how the series connects."""
    images = [Image.open(p).convert("RGB") for p in paths]
    # Downscale for a manageable preview
    scale = 0.28
    thumbs = [
        im.resize((int(im.width * scale), int(im.height * scale)), Image.Resampling.LANCZOS)
        for im in images
    ]
    gap = 18
    width = sum(t.width for t in thumbs) + gap * (len(thumbs) - 1)
    height = max(t.height for t in thumbs)
    strip = Image.new("RGB", (width, height), CREAM)
    x = 0
    for thumb in thumbs:
        strip.paste(thumb, (x, 0))
        x += thumb.width + gap
    path = out_dir / "_series-preview.png"
    strip.save(path, "PNG", optimize=True)
    return path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    raw_dir = root / "AppStoreScreenshots" / "6.7-inch"
    out_dir = root / "AppStoreScreenshots" / "marketing" / "6.7-inch"
    out_dir.mkdir(parents=True, exist_ok=True)

    missing = [s.source for s in SLIDES if not (raw_dir / s.source).exists()]
    if missing:
        print(f"Missing raw screenshots in {raw_dir}: {', '.join(missing)}", file=sys.stderr)
        print("Run Scripts/capture_app_store_screenshots.sh first.", file=sys.stderr)
        return 1

    fonts = load_fonts()
    written: list[Path] = []
    for slide in SLIDES:
        path = compose_slide(raw_dir, out_dir, fonts, slide)
        print(f"  • {path.name}")
        written.append(path)

    preview = stitch_panorama(out_dir, written)
    print(f"  • {preview.name} (series preview)")
    print(f"→ Saved to {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
