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
