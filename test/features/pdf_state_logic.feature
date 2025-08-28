Feature: PDF state logic

  Scenario: openPicked loads document and initializes state
    Given a new provider container
    When I openPicked with path {'test.pdf'} and pageCount {7}
    Then pdf state is loaded {true}
    And pdf picked path is {'test.pdf'}
    And pdf page count is {7}
    And pdf current page is {1}
    And pdf marked for signing is {false}

  Scenario: jumpTo clamps within page boundaries
    Given a new provider container
    And a pdf is open with path {'test.pdf'} and pageCount {5}
    When I jumpTo {10}
    Then pdf current page is {5}
    When I jumpTo {0}
    Then pdf current page is {1}
    When I jumpTo {3}
    Then pdf current page is {3}

  Scenario: setPageCount updates count without toggling other flags
    Given a new provider container
    And a pdf is open with path {'test.pdf'} and pageCount {2}
    When I toggle mark
    And I set page count {9}
    Then pdf page count is {9}
    And pdf state is loaded {true}
    And pdf marked for signing is {true}
