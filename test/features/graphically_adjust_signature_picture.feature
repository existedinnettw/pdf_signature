Feature: graphically adjust signature asset

  Scenario: Remove background
    Given a signature asset is selected
    When the user enables background removal
    Then near-white background becomes transparent in the preview
    And the user can apply the change

  Scenario: Adjust contrast and brightness
    Given a signature asset is selected
    When the user changes contrast and brightness controls
    Then the preview updates immediately
    And the user can apply or reset adjustments
