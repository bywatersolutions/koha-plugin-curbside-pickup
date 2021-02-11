# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.29] - 2021-02-11
## Changed
- Add support for handling 'phone' transports gracefully

## [1.0.28] - 2021-01-23
## Fixed
- Fix bug causing crash if a curbside pickup checkout is returned the same day.

## [1.0.27] - 2021-01-04
## Changed
- Add return to the same tab that you were on when changing a pickup status

## [1.0.26] - 2021-01-04
## Added
- Add classes to all "action" buttons for styling purposes

## [1.0.25] - 2020-12-18
## Changed
- Fixed bug related to new curbside_pickups_issues table where schema wasn't being loaded

## [1.0.24] - 2020-12-16
## Changed
- Added table curbside_pickups_issues to map a pickup to the issues & holds associated with a pickup

## [1.0.23] - 2020-12-10
## Changed
- Fix bug in OPAC that prevents patron from scheduling a new pickup unless all previous pickups are canceled/deleted

## [1.0.22] - 2020-11-20
## Changed
- Fix bug in OPAC that prevents patron from scheduling a new pickup unless all previous pickups are canceled/deleted

## [1.0.21] - 2020-11-18
## Changed
- Fix bug in OPAC javascript the prevents patron from scheduling a pickup

## [1.0.20] - 2020-11-04
## Changed
- Renamed OPAC javascript var in opac.js to avoid conflict with a var of the same name in Koha v20.05

## [1.0.17] - 2020-09-10
## Added
- Plugin now supports internationaliztion!
- Spanish translation

## [1.0.16] - 2020-09-01
## Changed
- Only show branches available for pickup in OPAC library selector.

## [1.0.15] - 2020-09-01
## Changed
- Fix bug caused by missing js variable

## [1.0.14] - 2020-08-31
## Changed
- Add 'loading' modal to OPAC while data is fetched for display

## [1.0.13] - 2020-08-27
## Changed
- Require unit tests to pass before building and releasing

## [1.0.12] - 2020-08-27
## Changed
- Update this changelog
- Remove installation step that is no longer required

## [1.0.11] - 2020-08-27
## Changed
- Add acknowledgements for original specification and design

## [1.0.10] - 2020-08-27
## Changed
- Plugin no longer requires bug 26163 to function

## [1.0.9] - 2020-08-17
## Changed
- Filter out holds from status tabs that are not waiting at the logged in library
- Disable submit button on staff side until a valid pickup slot is selected
- Disable submit button on opac side until a valid pickup slot is selected
- Ensure datepicker icon is disable correctly
- Add 'require' lines to API controller to ensure it has access to those modules

## [1.0.8] - 2020-08-17
## Added
- Specify the plugin module for the GitHub Action that builds the kpz file

## [1.0.7] - 2020-08-17
## Added
- Added documentation for CURBSIDE notice
- Added hyperlinks for various elements

## [1.0.6] - 2020-08-17
## Added
- Added default CURBSIDE notice
- Hours and minutes in configuration are now formatted correctly for 24-hour time

## [1.0.5] - 2020-08-17
## Changed
- Added support for CURBSIDE notice, which will be sent upon initial creation of a curbside pickup

## [1.0.4] - 2020-08-12
## Changed
- Remove dangling code, make fields required, prevent ISE when patron not found.

## [1.0.3] - 2020-08-11
## Added
- This changelog!

## [1.0.2] - 2020-08-11
### Changed
- Switched from `use` to `require` to allow installation to proceed without errors. Still requires plack to be restarted before using the plugin.
### Removed
- Installation debugging code.

## [1.0.1] - 2020-08-11
### Added
- Debugging for installation subroutine.

## [1.0.0] - 2020-08-11
### Added
- Initial release!

