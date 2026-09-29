#!/usr/bin/python3

import os
import subprocess
import sys
from pathlib import Path

def main() -> int:
    if len(sys.argv) != 2:
        print(f"!> Usage: {sys.argv[0]} /file/to/convert", file=sys.stderr)
        return 2

    src = Path(sys.argv[1])
    if not src.is_file():
        print(f"!> Input does not exist: {src}", file=sys.stderr)
        return 2
    if src.suffix.lower() != ".mp4":
        print(f"!> Refusing non-MP4 input: {src}", file=sys.stderr)
        return 2

    # Same directory/filesystem as source, so replacement is atomic.
    tmp = src.with_name(f".{src.stem}.h265-{os.getpid()}.mp4")
    cmd = [
        "ffmpeg", "-hide_banner", "-nostdin", "-i", str(src),
        # Main video + audio
        "-map", "0:v:0", "-map", "0:a?",
        # Preserve useful yt-dlp metadata/chapters
        "-map_metadata", "0", "-map_chapters", "0",
        # HEVC
        "-c:v", "libx265", "-preset", "medium", "-crf", "20", "-tag:v", "hvc1",
        # Audio should be AAC/M4A already
        "-c:a", "copy",
        # Put moov atom at beginning of MP4
        "-movflags", "+faststart",
        # Overwrite temp file
        "-y", str(tmp),
    ]

    try:
        # Do not touch the original unless ffmpeg completed successfully
        subprocess.run(cmd, check=True)
        os.replace(tmp, src)

    finally:
        # Remove partial output after ffmpeg failure
        try:
            tmp.unlink()
        except FileNotFoundError:
            pass

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
