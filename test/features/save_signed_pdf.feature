Feature: save signed document

  Scenario: Export the signed document to a new file
    Given a document is open and contains at least one signature placement
    When the user saves/exports the document
    Then a new document file is saved at specified full path, location and file name
    And the signature placements appear on the corresponding page in the output
    And keep other unchanged content(pages) intact in the output

  Scenario: Vector-accurate stamping into PDF page coordinates
    Given a signature placement is placed with a position and size relative to the page
    When the user saves/exports the document
    Then the signature placement is stamped at the exact PDF page coordinates and size
    And the stamp remains crisp at any zoom level (not rasterized by the screen)
    And other page content remains vector and unaltered

  Scenario: Prevent saving when nothing is placed
    Given a document is open with no signature placements placed
    When the user attempts to save
    Then the user is notified there is nothing to save

  Scenario: Loading sign when exporting/saving files
    Given a signature placement is placed with a position and size relative to the page
    When the user starts exporting the document
    And the export process is not yet finished
    Then the user is notified that the export is still in progress
    And the user cannot edit the document
