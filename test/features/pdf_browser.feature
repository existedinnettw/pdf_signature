Feature: document browser

  Background:
    Given a sample multi-page document (5 pages) is available

  Scenario: Open a document and navigate pages
    When the user opens the document
    Then the first page is displayed
    And the user can move to the next or previous page
    And the page label shows "Page {1} of {5}"

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

  Scenario: Go to clamps out-of-range inputs to valid bounds
    Given the document is open
    When the user enters {0} into the Go to input and applies it
    Then page {1} is displayed
    And the page label shows "Page {1} of {5}"
    When the user enters {99} into the Go to input and applies it
    Then the last page is displayed (page {5})
    And the page label shows "Page {5} of {5}"

  Scenario: Go to is disabled when no document is loaded
    Given no document is open
    Then the Go to input cannot be used

  Scenario: Open a different document will reset signature placements but keep signature cards
    Given the document is open
    When the user opens a different document with {3} pages
    And {1} signature placements exist on page {1}
    And {1} signature placements exist on page {2}
    And {2} signature cards exist
    Then the first page of the new document is displayed
    And the page label shows "Page {1} of {3}"
    And number of signature placements is {0}
    And {2} signature cards exist
