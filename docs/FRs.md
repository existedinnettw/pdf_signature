# Functional Requirements

## user stories

The following user stories may not use formal terminology as [meta-arch.md](./meta-arch.md) and use cases(`test/*.feature`), but use oral descriptions.

* name: [PDF browser](../test/features/pdf_browser.feature)
  * role: user
  * functionality: view and navigate PDF documents
  * benefit: select page to add signature
* name: [load signature](../test/features/load_signature.feature)
  * role: user
  * functionality: load a signature asset file and create a signature card
  * benefit: easily add signature to PDF
* name: [geometrically adjust signature picture](../test/features/geometrically_adjust_signature_picture.feature)
  * role: user
  * functionality: adjust the scale, rotation and position of the signature placement on the PDF page
  * benefit: ensure the signature fits well on the PDF page
* name: [graphically adjust signature picture](../test/features/graphically_adjust_signature_picture.feature)
  * role: user
  * functionality: background removal, contrast adjustment... to enhance the appearance of the signature asset within the signature card
  * benefit: easily improve the appearance of the signature on the PDF without additional software.
* name: [draw signature](../test/features/draw_signature.feature)
  * role: user
  * functionality: draw a signature asset using mouse or touch input
  * benefit: create a custom signature directly on the PDF if no pre-made signature is available.
* name: [save signed PDF](../test/features/save_signed_pdf.feature)
  * role: user
  * functionality: save/export the signed PDF document
  * benefit: easily keep a copy of the signed document for records.
* name: [preferences for app](../test/features/app_preferences.feature)
  * role: user
  * functionality: configure app preferences such as `language`, `theme`, `theme-color`.
  * benefit: customize the app experience to better fit user needs
* name: [remember preferences](../test/features/remember_preferences.feature)
  * role: user
  * functionality: remember user preferences for future sessions
  * benefit: provide a consistent and personalized experience
* name: [internationalizing](../test/features/internationalizing.feature)
  * role: user
  * functionality: app provide localization support
  * benefit: improve accessibility and usability for non-English speakers
* name: [support multiple signatures](../test/features/support_multiple_signatures.feature)
  * role: user
  * functionality: the ability to sign multiple locations within a PDF document
  * benefit: documents requiring multiple signatures can be signed simultaneously
* name: [support multiple signature pictures](../test/features/support_multiple_signature_pictures.feature)
  * role: user
  * functionality: the ability to use different signature pictures for different signing locations
  * benefit: close to real-world signing scenarios where every signature is not the same
