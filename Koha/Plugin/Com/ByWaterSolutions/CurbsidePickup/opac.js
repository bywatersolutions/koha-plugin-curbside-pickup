<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.27.0/moment.min.js" integrity="sha512-rmZcZsyhe0/MAjquhTgiUcb4d9knaFc7b5xAfju483gbEXTkeJRUMIPk6s3ySZMYUHEcjKbjLjyddGWMrNEvZg==" crossorigin="anonymous"></script>
<script>
let pickups;
let my_pickups;
let policies;
let existingPickupMomentsByLibrary = {};
let policiesByLibrary = {};
let enable_patron_scheduled_pickup = false;
let cp_borrowernumber;

$(document).ready(function() {
    cp_borrowernumber = $(".loggedinusername").data('borrowernumber');
    $("#menu ul li:first").after($("<li><a id='my-pickups' href='#'>your curbside pickups</li>"));

    $('body').on('change', '#datepicker', function() {
        // Grab the policy and list of existing curbside pickups based on the selected library
        let branchcode = $('#pickup-branch').val();
        let existingPickupMoments = existingPickupMomentsByLibrary[branchcode];
        let policy = policiesByLibrary[branchcode];

        var currentDate = $("#datepicker").datepicker("getDate");

        let selectedDate = moment(currentDate);

        let dow = selectedDate.format('dddd').toLowerCase();
        let start_hour = policy[dow + "_start_hour"];
        let start_minute = policy[dow + "_start_minute"];
        let end_hour = policy[dow + "_end_hour"];
        let end_minute = policy[dow + "_end_minute"];

        let pickup_interval = policy.pickup_interval;

        let listStartMoment = selectedDate.clone();
        listStartMoment.hour(start_hour);
        listStartMoment.minute(start_minute);
        let listEndMoment = selectedDate.clone();
        listEndMoment.hour(end_hour);
        listEndMoment.minute(end_minute);

        let pickup_times = [];
        let workingTimeMoment = listStartMoment.clone();
        let keep_going = true;
        let now = moment();

        // Initialize pickup slots starting at opening time
        let pickupIntervalStartMoment = workingTimeMoment.clone();
        let pickupIntervalEndMoment = pickupIntervalStartMoment.clone()
        pickupIntervalEndMoment.add(pickup_interval, 'minutes');
        let available_count = 0;
        let pickupSlots = [];
        while (keep_going) {

            let available = true;

            if (pickupIntervalStartMoment.isBefore(now)) {
                // Slots in the past are unavailable
                available = false;
            }

            if (pickupIntervalEndMoment.isAfter(listEndMoment)) {
                // Slots after the end of pickup times for the day are unavailable
                available = false;
            }

            let pickups_scheduled = 0;
            for (let i = 0; i < existingPickupMoments.length; i++) {
                let pickupMoment = existingPickupMoments[i];

                // An existing pickup time
                if (pickupMoment.isSameOrAfter(pickupIntervalStartMoment) && pickupMoment.isBefore(pickupIntervalEndMoment)) {
                    // This calculated pickup is in use by another scheduled pickup
                    pickups_scheduled++;
                }
            }

            if (pickups_scheduled >= policy.patrons_per_interval) {
                available = false;
            }

            pickupSlots.push({
                "available": available,
                "moment": pickupIntervalStartMoment.clone(),
                "pickups_scheduled": pickups_scheduled
            });

            if (available) available_count++;

            pickupIntervalStartMoment = pickupIntervalEndMoment.clone();
            pickupIntervalEndMoment.add(pickup_interval, 'minutes');
            if (pickupIntervalEndMoment.isAfter(listEndMoment)) {
                // This latest slot is after the end of pickup times for the day, so we can stop
                keep_going = false;
            }
        }

        $('#pickup-time').empty();
        for (let i = 0; i < pickupSlots.length; i++) {
            let pickupSlot = pickupSlots[i];
            let optText = pickupSlot.moment.format("LT");
            let optValue = pickupSlot.moment.format("YYYY-MM-DD HH:mm:ss");
            let pickups_scheduled = pickupSlot.pickups_scheduled;
            let disabled = pickupSlot.available ? "" : "disabled";
            $("#pickup-time").append(`<option value="${optValue}" ${disabled}>${optText} (${pickups_scheduled})</option>`);
        }

        $('#pickup-time').show();

        $('#schedule-pickup-button').prop('disabled', available_count <= 0);
    });

    // Adds the curbside pickups tab and the "your pickups" and "schedule a pickup" tab.
    $("#my-pickups").on("click", function() {
        show_wait_modal();
        get_api_data();
        hide_wait_modal();
    });

});

function get_my_pickups(borrowernumber) {
    return $.ajax({
        type: 'GET',
        url: `/api/v1/contrib/curbsidepickup/patrons/${borrowernumber}/pickups`,
        dataType: 'json',
        async: true,
        success: function(data) {
            my_pickups = data;
        }
    });
}

function get_policies() {
    return $.ajax({
        type: 'GET',
        url: `/api/v1/contrib/curbsidepickup/libraries/policies`,
        dataType: 'json',
        async: true,
        success: function(data) {
            policies = data;
        }
    });
}

function get_pickups() {
    return $.ajax({
        type: 'GET',
        url: `/api/v1/contrib/curbsidepickup/patrons/pickups`,
        dataType: 'json',
        async: true,
        success: function(data) {
            pickups = data;
        }
    });
}

function get_api_data() {
    $.when(
        get_my_pickups($(".loggedinusername").data('borrowernumber')),
        get_policies(),
        get_pickups()
    ).done(function() {
        update_data();
    });
}

function update_data() {
    existingPickupMomentsByLibrary = {};

    let newPoliciesByLibrary = {};
    for (let i = 0; i < policies.length; i++) {
        let policy = policies[i];

        newPoliciesByLibrary[policy.branchcode] = policy;
        // Initialize all the keys for existingPickupMomentsByLibrary as arrays
        existingPickupMomentsByLibrary[policy.branchcode] = [];

        $("#pickup-branch").find('option').remove();

        if (policy.enabled == "1" && policy.patron_scheduled_pickup == "1") {
            enable_patron_scheduled_pickup = true;
            $("#pickup-branch").append(`<option value="${policy.branchcode}">${policy.branchname}</option>`);
        }
    }
	policiesByLibrary = newPoliciesByLibrary;

    // Convert all the existing pickups into Moments for future use
    for (let i = 0; i < pickups.length; i++) {
        let pickup = pickups[i];
        let scheduled_pickup_datetime = pickup.scheduled_pickup_datetime;
        let pickupMoment = moment(scheduled_pickup_datetime);
        existingPickupMomentsByLibrary[pickup.branchcode].push(pickupMoment);
    }

    generate_html();
}

function generate_html() {
    $(".maincontent").replaceWith(function() {
        let tabs_and_table = `
                <div id='pickupdetails' class='maincontent'>
                    <h2>Curbside pickups</h2>
                    <div id="opac-user-views" class="toptabs">
                        <ul>
                            <li><a href="#opac-user-pickups">your pickups</a></li>
                            ${ enable_patron_scheduled_pickup ? `<li><a href="#opac-user-schedule-pickup">schedule a pickup</a></li>` : "" }
                        </ul>

                        <div id="opac-user-pickups">
                            <table id="pickups-table" class="table table-striped">
                                <thead>
                                    <tr>
                                        <th>Pickup library</td>
                                        <th>Date</th>
                                        <th>Time</th>
                                        <th>Notes</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody></tbody>
                            </table>
                        </div>
            `;

        let pickup_form = `
                        <div id="opac-user-schedule-pickup">
                            <fieldset class="rows">
                                <ol>
                                    <li>
                                        <label for="pickup_branch">Pickup library:</label>
                                        <select name="pickup_branch" id="pickup-branch">
                                            <option value="SELECT_A_LIBRARY">Select a library</option>
                                        </select>
                                        <span id="existing-pickup-warning" class="required">You already have a pickup scheduled for this library.</span>
                                    </li>
                                    <li>
                                        <label for="pickup_date">Pickup date:</label>
                                        <input name="pickup_date" type="text" class="form-control" id="datepicker" disabled required="required"/>
                                        <span class="required">Required</span>
                                        <select name="pickup_time" id="pickup-time" required="required"></select>
                                    </li>

                                    <li>
                                        <label for="notes">Notes:</label>
                                        <input name="notes" id="notes" />
                                    </li>
                                </ol>
                            </fieldset>

                            <div class="form-group">
                                <label class="col-sm-2"></label>
                                <div class="col-sm-10">
                                    <button id="schedule-pickup-button" class="btn btn-default" disabled>Schedule pickup</button>
                                </div>
                            </div>
                        </div>
            `;

        let closing_div = `</div>`;

        if (enable_patron_scheduled_pickup) {
            return tabs_and_table + pickup_form + closing_div;
        } else {
            return tabs_and_table + closing_div;
        }
    });

    $('#existing-pickup-warning').hide();

    $('#pickup-branch').on('change', function() {
        let branchcode = $(this).val();

        let existing_pickup = false;
        for (let i = 0; i < my_pickups.length; i++) {
            let p = my_pickups[i];
            if (!p.delivered_by && p.branchcode == branchcode) {
                existing_pickup = true;
            }
        }

        $('#datepicker').val("");
        $('#pickup-time').val("");
        $('#pickup-time').hide();
        $('#schedule-pickup-button').prop('disabled', true);

        if (existing_pickup) {
            $('#existing-pickup-warning').show();
            $('#datepicker').datepicker("option", "disabled", true);
        } else {
            $('#existing-pickup-warning').hide();
            $('#datepicker').datepicker("option", "disabled", branchcode == "SELECT_A_LIBRARY");
        }
    });

    $('#schedule-pickup-button').on('click', function() {
        $('#schedule-pickup-button').prop('disabled', true);

        let patron_id = cp_borrowernumber;
        let library_id = $('#pickup-branch').val();
        let pickup_datetime = $('#pickup-time').val();
        let notes = $('#notes').val();

        $('#pickup-branch').val("");
        $('#pickup-time').val("");
        $('#pickup-time').hide();
        $('#notes').val("");

        let data = {
            'library_id': library_id,
            'pickup_datetime': pickup_datetime,
            'notes': notes
        };

        $.ajax({
            type: "POST",
            url: `/api/v1/contrib/curbsidepickup/patrons/${patron_id}/pickup`,
            data: JSON.stringify(data),
            dataType: 'json',
            success: function(data) {
                $('#my-pickups').click();
            }
        });
    });

    // Populate the "Pickup library" pulldown with branches that have curbside pickups enabled
    for (let i = 0; i < policies.length; i++) {
        let policy = policies[i];
        if (policy.enabled == "1" && policy.patron_scheduled_pickup == "1") {
            $("#pickup-branch").append(`<option value="${policy.branchcode}">${policy.branchname}</option>`);
        }
    }

    $('.toptabs').tabs();

    $("#datepicker").datepicker();
    $('#datepicker').datepicker("option", "disabled", true);

    $("#pickup-time").hide();

    $("li.active").removeClass("active");
    $("#my-pickups").parent().addClass("active");

    $.getJSON(`/api/v1/contrib/curbsidepickup/patrons/${cp_borrowernumber}/pickups`, function(data) {
        my_pickups = data;

        for (let i = 0; i < data.length; i++) {
            let pickup = data[i];
            let arrived_disabled = !pickup.staged_datetime || pickup.arrival_datetime ? "disabled" : "";

            if ( pickup.delivered_datetime != null ) continue;

            let row = `
                        <tr>
                            <td>${pickup.branchname}</td>
                            <td>${moment(pickup.scheduled_pickup_datetime).format("L")}</td>
                            <td>${moment(pickup.scheduled_pickup_datetime).format("LT")}</td>
                            <td>${pickup.notes}</td>
                            <td>
                                <button class="btn arrival-alert ${arrived_disabled}" href="#" data-patron-id="${pickup.borrowernumber}" data-pickup-id="${pickup.id}" ${arrived_disabled}><i class="fa fa-bell" aria-hidden="true"></i> Alert staff of your arrival</button>
                                <p/>
                                <button class="btn cancel-pickup" href="#" data-patron-id="${pickup.borrowernumber}" data-pickup-id="${pickup.id}"><i class="fa fa-ban" aria-hidden="true"></i> Cancel this pickup</button>
                                </td>
                        </tr>
                    `;

            $("#pickups-table tbody").append(row);
        }
    });

    $('body').on('click', '.arrival-alert', function() {
        let button = $(this);
        let patron_id = $(this).data('patron-id');
        let pickup_id = $(this).data('pickup-id');

        $.getJSON(`/api/v1/contrib/curbsidepickup/patrons/${patron_id}/mark_arrived/${pickup_id}`, function(data) {
            if (data.error) {
                alert(data.error);
            } else {
                button.prop('disabled', true);
                button.addClass('disabled');
                alert("The library has been notified of your arrival");
            }
        })
    });

    $('body').on('click', '.cancel-pickup', function() {
        let button = $(this);
        let patron_id = $(this).data('patron-id');
        let pickup_id = $(this).data('pickup-id');

	if ( $(this).hasClass('disabled') ) return;

        let confirmed = confirm("Are you sure you want to cancel this scheduled curbside pickup?");
        if (confirmed) {
            $.ajax({
                type: "DELETE",
                url: `/api/v1/contrib/curbsidepickup/patrons/${patron_id}/pickup/${pickup_id}`,
                dataType: 'json',
                success: function(data) {
                    $('#my-pickups').click();
                    return false;
                }
            });

            return false;
        }

		return false;
    });
}

function show_wait_modal() {
    let modal = `
        <div id="curbside-wait-modal" class="modal fade" id="staticBackdrop" data-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="staticBackdropLabel" aria-hidden="true">
          <div class="modal-dialog" role="document">
                <div class="modal-content">
                  <div class="modal-header">
                        <h5 class="modal-title" id="staticBackdropLabel">Loading curbside pickups</h5>
                  </div>
                  <div class="modal-body">
                        <i class="fa fa-spinner fa-pulse fa-3x fa-fw"></i>
                        <span class="sr-only">Loading...</span>
                  </div>
                </div>
          </div>
        </div>`;

    $("body").append(modal);
    $("#curbside-wait-modal").modal();
}

function hide_wait_modal() {
    $("#curbside-wait-modal").modal('hide');
}
</script>
