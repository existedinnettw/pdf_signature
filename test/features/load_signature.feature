Feature: load signature asset

  Scenario Outline: Handle invalid or unsupported files
    Given the user selects "<file>"
    When the app attempts to load the asset
    Then the user is notified of the issue
    And the asset is not added to the document

    Examples:
      | file            |
      | 'corrupted.png' |
      | 'signature.bmp' |
      | 'empty.jpg'     |
      
  Scenario: Import a signature asset
    When the user chooses a image file as a signature asset
    Then the asset is loaded and shown as a signature asset

  Scenario: Import a signature card
    When the user chooses a signature asset to created a signature card
    Then the asset is loaded and shown as a signature card

  Scenario: Import a signature placement
    Given a created signature card
    When the user drags this signature card on the page of the document to place a signature placement
    Then a signature placement appears on the page based on the signature card

