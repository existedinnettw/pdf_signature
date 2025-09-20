Feature: support multiple signature placements

	Scenario: Place signature placements on different pages
		Given a multi-page document is open
		When the user places a signature placement on page {1}
		And the user navigates to page {3} and places another signature placement
		Then both signature placements are shown on their respective pages

	Scenario: Place multiple signature placements on the same page independently
		Given a document page is selected for signing
		When the user places two signature placements on the same page
		Then each signature placement can be dragged and resized independently
		And dragging or resizing one does not change the other

	Scenario: Reuse the same signature asset in multiple locations
		Given a signature asset loaded or drawn is wrapped in a signature card
		When the user drags it on the page of the document to place signature placements in multiple locations in the document
		Then identical signature placements appear in each location
		And adjusting one of the signature placements does not affect the others

	Scenario: Remove one of many signature placements
		Given three signature placements are placed on the current page
		When the user deletes one selected signature placement
		Then only the selected signature placement is removed
		And the other signature placements remain unchanged

	Scenario: Keep earlier signature placements while navigating between pages
		Given a signature placement is placed on page {2}
		When the user navigates to page {5} and places another signature placement
		Then the signature placement on page {2} remains
		And the signature placement on page {5} is shown on page {5}

	Scenario: Save a document with multiple signature placements across pages
		Given a document is open and contains multiple placed signature placements across pages
		When the user saves/exports the document
		Then all placed signature placements appear on their corresponding pages in the output
		And other page content remains unaltered

