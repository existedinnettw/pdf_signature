# meta archietecture

* [MVVM](https://docs.flutter.dev/app-architecture/guide)

## Package structure

The repo structure follows official [Package structure](https://docs.flutter.dev/app-architecture/case-study#package-structure) with slight modifications.

* put each `<FEATURE NAME>/`s in `features/` sub-directory under `ui/`.
* `test/features/` contains BDD unit tests for each feature. It focuses on pure logic, therefore will not access `View` but `ViewModel` and `Model`.
* `test/widget/` contains UI widget(component) tests which focus on `View` from MVVM of each component.
* `integration_test/` for integration tests. They should be volatile to follow UI layout changes.
