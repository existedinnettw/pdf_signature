Feature: support multiple signature pictures

	Scenario: Place signatures on different pages with different images
		Given a multi-page PDF is open
		When the user places a signature from picture <first_image> on page <first_page>
		And the user places a signature from picture <second_image> on page <second_page>
		Then both signatures are shown on their respective pages
		Examples:
            # Same page, same image
            # Same page, different images
            # Different pages, same image
            # Different pages, different images
			| first_image | first_page | second_image | second_page |
            | 'alice.png' | 1          | 'alice.png'  | 1           | 
            | 'alice.png' | 1          | 'bob.png'    | 1           | 
			| 'alice.png' | 1          | 'bob.png'    | 3           | 
			| 'bob.png'   | 2          | 'alice.png'  | 5           |

	Scenario: Reuse the same image for more than one signature
		Given a signature image is loaded or drawn
		When the user places it in multiple locations in the document
		Then identical signature instances appear in each location
		And adjusting one instance does not affect the others

	Scenario: Reassign a different image to an existing signature
		Given a PDF page is selected for signing
		And an image {"alice.png"} is loaded
		And the user places a signature on the page
		When an image {"bob.png"} is loaded
		And the user assigns {"bob.png"} to the selected signature
		Then the selected signature is shown with image {"bob.png"}

	Scenario: Save/export uses the assigned image for each signature
		Given a PDF is open and contains multiple placed signatures across pages
		When the user saves/exports the document
		Then all placed signatures appear on their corresponding pages in the output
		And other page content remains unaltered

