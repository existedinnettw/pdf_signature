# meta archietecture

* [MVVM](https://docs.flutter.dev/app-architecture/guide)
  * [Data layer](https://docs.flutter.dev/app-architecture/case-study/data-layer)
    * View ⇆ ViewModel ⇆ Repository ⇆ Service
      * Model is used across.

## Package structure

The repo structure follows official [Package structure](https://docs.flutter.dev/app-architecture/case-study#package-structure) with slight modifications.

* put each `<FEATURE NAME>/`s in `features/` sub-directory under `ui/`.
* `test/features/` contains BDD unit tests for each feature. It focuses on pure logic, therefore will not access `View` but `ViewModel` and `Model`.
* `test/widget/` contains UI widget(component) tests which focus on `View` from MVVM of each component.
* `integration_test/` for integration tests. They should be volatile to follow UI layout changes.

Some rule of thumb:
* `<object>Provider` only placed at `/lib/data/repositories/` or `/lib/data/services/` to provide data source.

## Abstraction

### terminology

* signature asset
  * image file of a signature, stored in the device or cloud storage
    * can drawing from canvas
* signature card
  * template of signature placement
  * It will include modifications such as brightness, contrast, background removal, rotation of the signature asset.
* signature placement
  * placed modified signature asset from signature card on a specific position on a specific page of a specific PDF document
* document
  * PDF document to be signed

## key dependencies

* [pdfrx](https://pub.dev/packages/pdfrx)
  * [packages/pdfrx/example/viewer/lib/main.dart](https://github.com/espresso3389/pdfrx/blob/master/packages/pdfrx/example/viewer/lib/main.dart)
  * When using pdfrx, developers should control view function e.g. zoom, scroll... by component of pdfrx e.g. `PdfViewer`, rather than introduce additional view.
    * [PdfViewer could not be scrollable when nested inside SingleChildScrollView #27](https://github.com/espresso3389/pdfrx/issues/27)
    * [How to zoom in PdfPageView #244](https://github.com/espresso3389/pdfrx/issues/244)
  * So does overlay some widgets, they should be placed using the provided overlay builder.
    * [Viewer Customization using Widget Overlay](https://pub.dev/documentation/pdfrx/latest/pdfrx/PdfViewerParams/viewerOverlayBuilder.html)
    * [Per-page Customization using Widget Overlay](https://pub.dev/documentation/pdfrx/latest/pdfrx/PdfViewerParams/pageOverlaysBuilder.html)
      * `pageOverlaysBuilder`
