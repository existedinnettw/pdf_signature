Feature: internationalizing

  Scenario: Default language follows the device locale on first launch
    When the app launches
    Then the language is set to the device locale

  Scenario: Invalid stored language falls back to the device locale
    Given stored preferences contain theme {"sepia"} and language {"xx"}
    When the app launches
    Then the language falls back to the device locale

  Scenario: Supported languages are available
    Then the app supports languages
      | 'en'    |
      | 'zh-TW' |
      | 'es'    |
