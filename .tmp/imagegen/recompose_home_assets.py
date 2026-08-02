from collections import deque
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets" / "images"
TARGET_SIZE = (1800, 1000)


def recompose_hero(source_name: str, output_name: str) -> None:
    source = Image.open(ASSETS / source_name).convert("RGB")

    backdrop = ImageOps.fit(
        source,
        TARGET_SIZE,
        method=Image.Resampling.LANCZOS,
        centering=(0.5, 0.5),
    ).filter(ImageFilter.GaussianBlur(42))
    backdrop = ImageEnhance.Color(backdrop).enhance(1.08)
    backdrop = ImageEnhance.Contrast(backdrop).enhance(0.92)

    overlay = Image.new("RGBA", TARGET_SIZE, (8, 8, 10, 36))
    canvas = Image.alpha_composite(backdrop.convert("RGBA"), overlay)

    scale = TARGET_SIZE[0] / source.width
    foreground_height = round(source.height * scale)
    foreground = source.resize(
        (TARGET_SIZE[0], foreground_height), Image.Resampling.LANCZOS
    )
    foreground = ImageEnhance.Sharpness(foreground).enhance(1.08).convert("RGBA")

    feather = min(42, max(12, foreground_height // 14))
    mask = Image.new("L", foreground.size, 255)
    alpha = mask.load()
    for y in range(feather):
        opacity = round(255 * (y + 1) / feather)
        for x in range(foreground.width):
            alpha[x, y] = opacity
            alpha[x, foreground.height - 1 - y] = opacity
    foreground.putalpha(mask)

    y = (TARGET_SIZE[1] - foreground_height) // 2
    canvas.alpha_composite(foreground, (0, y))
    canvas.convert("RGB").save(ASSETS / output_name, quality=96)


def is_connected_background(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _ = pixel
    maximum = max(red, green, blue)
    minimum = min(red, green, blue)
    return minimum >= 208 and maximum - minimum <= 28


def cut_out_offer() -> None:
    source_path = ROOT / ".tmp" / "imagegen" / "offer_source.png"
    image = Image.open(source_path).convert("RGBA")
    width, height = image.size
    pixels = image.load()
    visited = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def enqueue(x: int, y: int) -> None:
        offset = y * width + x
        if visited[offset] or not is_connected_background(pixels[x, y]):
            return
        visited[offset] = 1
        queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        pixels[x, y] = (*pixels[x, y][:3], 0)
        if x:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)

    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise RuntimeError("Offer extraction produced an empty image")

    left, top, right, bottom = bounds
    padding = 8
    crop_box = (
        max(0, left - padding),
        max(0, top - padding),
        min(width, right + padding),
        min(height, bottom + padding),
    )
    output = image.crop(crop_box)
    if output.mode != "RGBA" or output.getchannel("A").getextrema()[0] != 0:
        raise RuntimeError("Offer extraction did not preserve transparency")
    output.save(ASSETS / "first_order_offer_v2.png", optimize=True)


for index in range(1, 4):
    recompose_hero(f"home_hero_{index}.png", f"home_hero_{index}_mobile.png")

cut_out_offer()

