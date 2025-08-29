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
      | 'corrupted.png' |
      | 'signature.bmp' |
      | 'empty.jpg'     |
