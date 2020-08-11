<script>
$(document).ready(function() {
    let button = `<a id="create-pickup" href="#" class="btn btn-default"><i class="fa fa-car"></i> Schedule pickup</a>`;
    $("#addnewmessageLabel").after(button);
    $('#create-pickup').on('click', function(){
        let borrowernumber = $("#editpatron").attr('href').split("=").slice(-1)[0];
        let url = `/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AByWaterSolutions%3A%3ACurbsidePickup&method=tool&action=find-patron&tab=schedule-pickup&borrowernumber=${borrowernumber}`;
        window.location = url;
    });
});
</script>
