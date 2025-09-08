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
- Minimal top bar with app name and a "Configure" button with a gear icon for settings.
- Clean layout encouraging first action.

Illustration:

![](wireframe.assets/first_screen.excalidraw)

## Settings dialog

Purpose: provide basic configuration before/after opening a PDF.
Route: root --> settings

Design notes:
- Opened via "Configure" button in the top bar.
- Modal with simple sections (e.g., General, Display).
- Primary action to save, secondary to cancel.

Illustration:

![](wireframe.assets/with_configure_screen.excalidraw)

## PDF opened

Purpose: view and navigate the PDF; for signature placement.
Route: root --> opened

Design notes:
- Top: A small toolbar sits at the top edge with file name text, open pdf file button, previous/next page widgets and zoom controls.
  - On the far left of the toolbar there is a button that can turn the document pages overview sidebar on and off.
  - On the far right of the toolbar there is a button that can turn the signature cards overview sidebar on and off.
  - Navigation: Previous page, Next page, and a page number input (e.g., “2 / 10”) with jump-on-Enter.
  - Zoom: Zoom out, Zoom level dropdown (percent), Zoom in, Fit width, Fit page, Reset zoom.
  - Optional: Find/search within PDF (if supported by engine).
- Left pane: vertical strip of page thumbnails (e.g., page1, page2, page3). Clicking a thumbnail navigates to that page; the current page is visually indicated.
- Center: main PDF viewer shows the active page. 
  - wheel to scroll pages.
  - Ctrl/Cmd + wheel to zoom.
- Right pane: signatures drawer displaying saved signatures as cards.
  - able to drag and drop signature cards onto the PDF as placed signatures.
  - Each signature card shows a preview.
    - long tap/right-click will show menu with options to delete, Adjust graphic of image.
      - "Adjust graphic" opens a simple image editor, which can remove backgrounds, Rotate (rotation handle).
  - There is an empty card with "new signature" prompt and 2 buttons: "from file" and "draw".
    - "from file" opens a file picker to select an image as a signature card.
    - "draw" opens a simple drawing interface (draw canvas) to create a signature card.
- Interaction: drag a signature card from the right drawer onto the currently visible page to place it.

Signature controls (after placing on page):
- Select to show bounding box with resize handles and a small inline action bar.
- Actions: Move (drag), Resize (corner/side handles), Delete (trash icon or Delete key).
- Lock: Lock/Unlock position.
- Keyboard: Arrow keys to nudge (Shift for 10px); Shift-resize to keep aspect; Esc to cancel; Ctrl/Cmd+D to duplicate; Del/Backspace to delete.

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
