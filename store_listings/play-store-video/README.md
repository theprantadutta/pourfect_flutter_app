# Play Store video

- **Live:** https://www.youtube.com/watch?v=E9kBGJYoCP8 (set as the Play
  listing's video). Play wants the watch URL, never a `/shorts/` one.
- `pourfect-promo-landscape.mp4`: 1920x1080, 77 s, 30 fps, light Toybox look.
- `youtube-thumbnail-1280x720.png`: the feature graphic
  (`assets/brand/pourfect_feature_graphic_1024x500.png`) scaled to 1280 wide,
  with a blurred copy of itself filling above and below.

Made 2026-11-15 the same way as Snake Classic's video.

## How it was made

1. **Footage:** `adb shell screenrecord --bit-rate 8000000` on the A24 (shared
   with other sessions: ask first). Stop with `adb shell pkill -INT
   screenrecord`, because killing adb corrupts the mp4. Each clip is capped at
   about 180 s.
2. **Gameplay:** a demo build from the local branch `demo/promo-video` (never
   merge it): `flutter build apk --debug --dart-define=DEMO_AUTOPILOT=true
   --dart-define=DEMO_SEED=24`. Each campaign board solves itself at par, ads
   and prompts are off, and progress starts at 24 solved. It talks to no
   production server.
3. **Music:** the game's own synthesized menu loop. `tools/export_music.dart`
   writes it to WAV; copy the script into `tool/` and `dart run` it.
4. **Edit:** `python tools/pourfect_render.py <ffmpeg.exe> tools/pourfect_scenes.json
   <music.wav> out.mp4`, with the clips next to the script. It uses Pillow and
   the ffmpeg bundled with `imageio_ffmpeg`. The raw recordings are not kept.
