Feature: Signature state logic

  Scenario: placeDefaultRect centers a reasonable default rect
    Given a new provider container
    Then signature rect is null
    When I place default signature rect
    Then signature rect left >= {0}
    And signature rect top >= {0}
    And signature rect right <= {400}
    And signature rect bottom <= {560}
    And signature rect width > {50}
    And signature rect height > {20}

  Scenario: drag clamps to canvas bounds
    Given a new provider container
    And a default signature rect is placed
    When I drag signature by {Offset(10000, -10000)}
    Then signature rect left >= {0}
    And signature rect top >= {0}
    And signature rect right <= {400}
    And signature rect bottom <= {560}
    And signature rect moved from center

  Scenario: resize respects aspect lock and clamps
    Given a new provider container
    And a default signature rect is placed
    And aspect lock is {true}
    When I resize signature by {Offset(1000, 1000)}
    Then signature aspect ratio is preserved within {0.05}
    And signature rect left >= {0}
    And signature rect top >= {0}
    And signature rect right <= {400}
    And signature rect bottom <= {560}

  Scenario: setImageBytes ensures a rect exists for display
    Given a new provider container
    Then signature rect is null
    When I set tiny signature image bytes
    Then signature image bytes is not null
    And signature rect is not null
