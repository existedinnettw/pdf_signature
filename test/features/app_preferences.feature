Feature: App preferences

  Scenario Outline: Choose a theme and apply it immediately
    Given the settings screen is open
    When the user selects the "<theme>" theme
    Then the app UI updates to use the "<theme>" theme
    And the preference {theme} is saved as {"<theme>"}

    Examples:
      | theme  |
      | 'light'  |
      | 'dark'   |
      | 'system' |

  Scenario Outline: Choose a language and apply it immediately
    Given the settings screen is open
    When the user selects a supported language "<language>"
    Then all visible texts are displayed in "<language>"
    And the preference {language} is saved as {"<language>"}

    Examples:
      | language |
      | 'en'       |
      | 'zh-TW'    |
      | 'es'       |

