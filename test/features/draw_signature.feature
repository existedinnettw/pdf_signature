Feature: draw signature

  Scenario: Draw with mouse or touch and place on page
    Given an empty signature canvas
    When the user draws strokes and confirms
    Then a signature image is created
    And it is placed on the selected page

  Scenario: Clear and redraw
    Given a drawn signature exists in the canvas
    When the user clears the canvas
    Then the canvas becomes blank

  Scenario: Undo the last stroke
    Given multiple strokes were drawn
    When the user chooses undo
    Then the last stroke is removed
