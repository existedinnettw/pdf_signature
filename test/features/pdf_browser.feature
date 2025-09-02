Feature: PDF browser

  Background:
    Given a sample multi-page PDF (5 pages) is available

  Scenario: Open a PDF and navigate pages
    When the user opens the document
    Then the first page is displayed
    And the user can move to the next or previous page
    And the page label shows "Page {1} of {5}"

  Scenario: Jump to a specific page by typing Enter
    Given the document is open
    When the user types {3} into the Go to input and presses Enter
    Then page {3} is displayed
    And the page label shows "Page {3} of {5}"
    And the left pages overview highlights page {3}

  Scenario: Jump to a specific page using the Apply button
    Given the document is open
    When the user types {4} into the Go to input
    And the user clicks the Go to apply button
    Then page {4} is displayed
    And the page label shows "Page {4} of {5}"

  Scenario: Navigate via page thumbnails
    Given the document is open
    When the user clicks the thumbnail for page {2}
    Then page {2} is displayed
    And the page label shows "Page {2} of {5}"

  Scenario: Continuous mode scrolls target page into view on jump
    Given the document is open
    And the Page view mode is set to Continuous
    When the user jumps to page {5}
    Then page {5} becomes visible in the scroll area
    And the left pages overview highlights page {5}



  Scenario: Go to clamps out-of-range inputs to valid bounds
    Given the document is open
    When the user enters {0} into the Go to input and applies it
    Then page {1} is displayed
    And the page label shows "Page {1} of {5}"
    When the user enters {99} into the Go to input and applies it
    Then the last page is displayed (page {5})
    And the page label shows "Page {5} of {5}"

  Scenario: Go to is disabled when no PDF is loaded
    Given no document is open
    Then the Go to input cannot be used
