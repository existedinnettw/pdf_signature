Feature: remember preferences

  Scenario Outline: Remember preferences across app restarts
    Given the user previously set theme {"<theme>"} and language {"<language>"}
    When the app launches
    Then the app UI theme is {"<theme>"}
    And the app language is {"<language>"}

    Examples:
      | theme  | language |
      | 'dark'   | 'en'       |
      | 'light' | 'zh-TW'    |
      | 'system' | 'es'       |

  Scenario: Follow system appearance when theme is set to system
    Given the user selects the "system" theme
    And the OS appearance switches to dark mode
    When the app is resumed or returns to foreground
    Then the app UI updates to use the "dark" theme

  Scenario: Reset preferences to defaults
    Given the user has theme {"dark"} and language {"es"} saved
    When the user taps "Reset to defaults"
    Then the theme is set to {"system"}
    And the language is set to the device locale
    And both preferences are saved

  Scenario: Ignore invalid stored values and fall back safely
    Given stored preferences contain theme {"sepia"} and language {"xx"}
    When the app launches
    Then the theme falls back to {"system"}
    And the language falls back to the device locale
    And invalid values are replaced with valid defaults in storage
