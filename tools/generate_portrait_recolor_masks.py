"""Generate runtime recolor masks for the ImageGen portrait roster.

Tool-only dependencies: ``pip install anime_seg pillow numpy``.
The runtime consumes the generated PNG masks and does not load the model.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


CLASS_COLORS = {
    "skin": np.array([255, 220, 180], dtype=np.uint8),
    "face": np.array([100, 150, 255], dtype=np.uint8),
    "hair": np.array([255, 0, 0], dtype=np.uint8),
    "clothes": np.array([180, 0, 255], dtype=np.uint8),
}


def _channel(segmentation: np.ndarray, *class_names: str) -> Image.Image:
    selected = np.zeros(segmentation.shape[:2], dtype=np.uint8)
    for class_name in class_names:
        selected[np.all(segmentation == CLASS_COLORS[class_name], axis=2)] = 255
    return Image.fromarray(selected, mode="L").filter(ImageFilter.GaussianBlur(1.25))


def _write_control_mask(segmented: Image.Image, destination: Path) -> None:
    segmentation = np.asarray(segmented.convert("RGB"), dtype=np.uint8)
    hair = _channel(segmentation, "hair")
    skin = _channel(segmentation, "skin", "face")
    clothes = _channel(segmentation, "clothes")
    opaque = Image.new("L", segmented.size, 255)
    control_mask = Image.merge("RGBA", (hair, skin, clothes, opaque))
    destination.parent.mkdir(parents=True, exist_ok=True)
    control_mask.save(destination, optimize=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--portrait-dir",
        type=Path,
        default=Path("assets/runtime/ui/portraits"),
    )
    parser.add_argument("--size", type=int, default=512)
    args = parser.parse_args()

    from anime_seg import AnimeSegPipeline

    portraits = sorted(
        path
        for path in args.portrait_dir.glob("runner-portrait-*.png")
        if "-recolor-mask" not in path.stem
    )
    if not portraits:
        raise SystemExit(f"No portraits found under {args.portrait_dir}")

    pipeline = AnimeSegPipeline.from_dinoV2().to("cpu")
    for portrait in portraits:
        segmented = pipeline(str(portrait), width=args.size, height=args.size)
        destination = portrait.with_name(f"{portrait.stem}-recolor-mask.png")
        _write_control_mask(segmented, destination)
        print(f"MASK {portrait.name} -> {destination.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
