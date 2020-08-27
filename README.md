# Curbside Pickup plugin for Koha

## Downloading
From the [release page](https://github.com/bywatersolutions/koha-plugin-curbside-pickup/releases) you can download the last KPZ file.

## Configuration
The plugin configuration has a tab for each library set up in your Koha instance.
Each tab the following options:

### Enable
Simply put, the option enables curbside pickups for this libxrary.

### Pickup interval
This is the amount of time allotted for each pickup.
For example, if the value is set to `30`, each pickup slot will be 30 minutes long.
For best results, use whole fractions of an hour ( 10, 15, 20, 30, 60 ).

### Maximum patrons per interval
This is the number of simultaneous pickups that may occupy a single time slot.
For example, if it is set to 3, then up to three patrons may have pickups scheduled for the same pickup time.

### Patron-scheduled pickup
If this option is enabled, patrons may schedule their own pickup times.
If not enabled, librarians can still schedule pickups for patrons from the staff interface.

### Curbside pickup hours
This section lets you specify the start and end time for curbside pickups for each day of the week.
The time is specificed in 24 hour format ( e.g. 0:00 to 23:59 ).
Leave all four boxes empty for days that you do not want to have pickup hours.

## Usage
To use the plugin, browse to the plugins page and select the `Tool` option for the plugin.
For your convenience, this plugin also adds a 'Schedule pickup' button to the patrons toolbar that will allow you to schedule a pickup for that patron without searching for them first.

### Workflow
Each pickup moves through a lifecycle as follows:

#### To be staged
This is a brand new pickup request.
Any pickup in this status needs waiting holds for the pickup to be gathered.
Once materials are gathered, click `Mark as staged & ready` to move to the next step.

#### Staged & ready
This status indicates the materials have been gathered and are waiting for the patron.
At this stage, either the patron or a librarian can mark the pickup as "Patron has arrived" to indicate they are ready and waiting.

#### Patron is outside
At this status, it is time to take the items out to the patron.
The `Mark as delivered` button will check out the items to the patron and mark the pickup as delivered.

#### Delivered today
This tab lists all pickups completed today.

#### Schedule pickup
This tab contains the form to schedule a new curbside pickup.
Simply search for the patron's cardnumber or use the "Schedule pickup" button on the patron record.
Choose the pickup day and a list of times will display.
To the right of the given time, in parentheses is the number of pickups already scheduled for that time slot.

When a pickup is scheduled, Koha will look for a `CURBSIDE` notice in the Holds module.
If this notice exists it will be sent to the patron.
This notice supports email and SMS.
A default version of this notice should have been installed by the plugin.

## Acknowledgments
This plugin was originally developed following a specification and design
created by staff members from the Equinox Open Library Initiative, including
Andrea Buntz Neiman, Sally Fortin, and Galen Charlton.
