# Brand fonts (licensed)

These fonts are **commercial / licensed** and are deliberately **not** committed
to the repo. The app runs fine without them — it falls back to free Google Fonts
(Fraunces for headers, Outfit for body) until the real files are added.

## Fonts to add

| Role | Font | Foundry | Family name expected in code |
|------|------|---------|------------------------------|
| Headers | **Ogg** (1st choice) / Canela / Chronicle Display | Sharp Type / Commercial Type / Hoefler&Co. | `Ogg` |
| Body & subheaders | **LL Circular** | Lineto | `Circular` |

## How to enable

1. Purchase a licence and download the `.otf`/`.ttf` files.
2. Drop them in this folder (`assets/fonts/`). Suggested filenames:
   - `Ogg-Regular.otf`, `Ogg-Medium.otf`
   - `LLCircular-Book.otf`, `LLCircular-Medium.otf`, `LLCircular-Bold.otf`
3. Un-comment the `fonts:` block in `pubspec.yaml` and adjust the asset paths /
   weights to match the files you actually have.
4. Run `flutter pub get` and rebuild. No Dart changes needed — `lib/themes/app_theme.dart`
   already requests the `Ogg` and `Circular` families first.

> Keep these files out of version control if your licence forbids redistribution.
> Consider adding `assets/fonts/*.otf` and `*.ttf` to `.gitignore`.
