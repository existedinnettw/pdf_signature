# Use cases

Use cases are derived from `FRs.md` (user stories) and `meta-arch.md`. Each Feature name matches the corresponding user story; scenarios focus on observable behavior without restating story details.

```gherkin
Feature: PDF browser

	Scenario: Open a PDF and navigate pages
		Given a PDF document is available
		When the user opens the document
		Then the first page is displayed
		And the user can move to the next or previous page

	Scenario: Jump to a specific page
		Given a multi-page PDF is open
		When the user selects a specific page number
		Then that page is displayed

	Scenario: Select a page for signing
		Given a PDF is open
		When the user marks the current page for signing
		Then the page is set as the signature target
```

```gherkin
Feature: load signature picture

	Scenario: Import a signature image
		Given a PDF page is selected for signing
		When the user chooses a signature image file
		Then the image is loaded and shown as a signature asset

	Scenario Outline: Handle invalid or unsupported files
		Given the user selects "<file>"
		When the app attempts to load the image
		Then the user is notified of the issue
		And the image is not added to the document

		Examples:
			| file            |
			| corrupted.png   |
			| signature.bmp   |
			| empty.jpg       |
```

```gherkin
Feature: geometrically adjust signature picture

	Scenario: Resize and move the signature within page bounds
		Given a signature image is placed on the page
		When the user drags handles to resize and drags to reposition
		Then the size and position update in real time
		And the signature remains within the page area

	Scenario: Lock aspect ratio while resizing
		Given a signature image is selected
		When the user enables aspect ratio lock and resizes
		Then the image scales proportionally
```

```gherkin
Feature: graphically adjust signature picture

	Scenario: Remove background
		Given a signature image is selected
		When the user enables background removal
		Then near-white background becomes transparent in the preview
		And the user can apply the change

	Scenario: Adjust contrast and brightness
		Given a signature image is selected
		When the user changes contrast and brightness controls
		Then the preview updates immediately
		And the user can apply or reset adjustments
```

```gherkin
Feature: draw signature

	Scenario: Draw with mouse or touch and place on page
		Given an empty signature canvas
		When the user draws strokes and confirms
		Then a signature image is created
		And it is placed on the selected page

	Scenario: Clear and redraw
		Given a drawn signature exists in the canvas
		When the user clears the canvas
		Then the canvas becomes blank

	Scenario: Undo the last stroke
		Given multiple strokes were drawn
		When the user chooses undo
		Then the last stroke is removed
```

