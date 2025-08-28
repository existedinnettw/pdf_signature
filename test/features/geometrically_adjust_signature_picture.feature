Feature: geometrically adjust signature picture

  Scenario: Resize and move the signature within page bounds
    Given a signature image is placed on the page
    When the user drags handles to resize and drags to reposition
    Then the size and position update in real time
    And the signature remains within the page area

  Scenario: Lock aspect ratio while resizing
    Given a signature image is selected
    When the user enables aspect ratio lock and resizes
    Then the image scales proportionally
