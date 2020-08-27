# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

