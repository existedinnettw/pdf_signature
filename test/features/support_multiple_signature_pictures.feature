Feature: support multiple signature assets

	Scenario: Place signature placements on different pages with different assets
		Given a multi-page document is open
		When the user places a signature placement from asset <firstAsset> on page <firstPage>.
		And the user places a signature placement from asset <secondAsset> on page <secondPage>.
		Then both signature placements are shown on their respective pages
		Examples:
			| firstAsset  | firstPage  | secondAsset  | secondPage  |
            | 'alice.png' | 1          | 'alice.png'  | 1           | 
            | 'alice.png' | 1          | 'bob.png'    | 1           | 
			| 'alice.png' | 1          | 'bob.png'    | 3           | 
			| 'bob.png'   | 2          | 'alice.png'  | 5           |

	Scenario: Reuse the same asset for more than one signature placement
		Given a signature asset is loaded or drawn
		When the user places it in multiple locations in the document
		Then identical signature instances appear in each location
		And adjusting one instance does not affect the others

	Scenario: Save/export uses the assigned asset for each signature placement
		Given a document is open and contains multiple placed signature placements across pages
		When the user saves/exports the document
		Then all placed signature placements appear on their corresponding pages in the output
		And other page content remains unaltered

