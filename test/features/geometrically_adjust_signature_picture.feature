Feature: geometrically adjust signature asset

  Scenario: Resize and move the signature within page bounds
    Given a signature asset is placed on the page
    When the user drags handles to resize and drags to reposition
    Then the size and position update in real time
    And the signature placement remains within the page area

  Scenario: Rotate the signature
    Given a signature asset is placed on the page
    When the user uses rotate controls
    Then the signature placement rotates around its center in real time
    And resize to fit within bounding box