# Wireframes

This document contains the product wireframes drawn in Excalidraw. The editable sources live under `docs/wireframe.assets/*.excalidraw`. For easy viewing, we generate an SVG-based copy at `docs/.wireframe.md`.

<!--
Note: `.excalidraw.svg` is a special Excalidraw-flavored SVG. We keep `.excalidraw` as the editable source and export to `.svg` for documentation preview.
Refs:
- https://github.com/excalidraw/excalidraw
- https://github.com/excalidraw/svg-to-excalidraw
-->

## Welcome / First screen

Purpose: let the user open a PDF quickly via drag & drop or file picker.
Route: root

Design notes:
- Central drop zone with hint text: “Drag a PDF here or click to select”.
- Minimal top bar with app name and a gear icon for settings.
- Clean layout encouraging first action.

Illustration:

![](wireframe.assets/first_screen.excalidraw)

## Settings dialog

Purpose: provide basic configuration before/after opening a PDF.
Route: root --> settings

Design notes:
- Opened via gear icon in the top bar.
- Modal with simple sections (e.g., General, Display).
- Primary action to save, secondary to cancel.

Illustration:

![](wireframe.assets/with_configure_screen.excalidraw)

## PDF opened

Purpose: view and navigate the PDF; prepare for signature placement.
Route: root --> opened

Design notes:
- Main canvas shows the current page.
- Navigation: previous/next page, zoom controls are placed in toolbar which is at top of main PDF canvas.
- Drag signature onto page.

Illustration:

![](wireframe.assets/with_pdf_opened.excalidraw)

---

## How to view and export

We keep links in this file pointing to `.excalidraw`. To preview the SVGs and generate `docs/.wireframe.md` with `.svg` links, run from repo root:

    dart run tool/gen_view_wireframe_md.dart

This will:
- Copy `docs/wireframe.md` to `docs/.wireframe.md` and rewrite image links to `.svg`.
- Export any `*.excalidraw` under `docs/` to `*.svg` if they are new or modified.

## Next wireframes (optional)

- Save/Export result dialog and success state.
