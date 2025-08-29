Feature: support multiple signatures

	Scenario: Place signatures on different pages
		Given a multi-page PDF is open
		When the user places a signature on page 1
		And the user navigates to page 3 and places another signature
		Then both signatures are shown on their respective pages

	Scenario: Place multiple signatures on the same page independently
		Given a PDF page is selected for signing
		When the user places two signatures on the same page
		Then each signature can be dragged and resized independently
		And dragging or resizing one does not change the other

	Scenario: Reuse the same signature asset in multiple locations
		Given a signature image is loaded or drawn
		When the user places it in multiple locations in the document
		Then identical signature instances appear in each location
		And adjusting one instance does not affect the others

	Scenario: Remove one of many signatures
		Given three signatures are placed on the current page
		When the user deletes one selected signature
		Then only the selected signature is removed
		And the other signatures remain unchanged

	Scenario: Keep earlier signatures while navigating between pages
		Given a signature is placed on page 2
		When the user navigates to page 5 and places another signature
		Then the signature on page 2 remains
		And the signature on page 5 is shown on page 5

	Scenario: Save a document with multiple signatures across pages
		Given a PDF is open and contains multiple placed signatures across pages
		When the user saves/exports the document
		Then all placed signatures appear on their corresponding pages in the output
		And other page content remains unaltered

