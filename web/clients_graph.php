<?php
foreach ($CLIENT_NUMBERS as $STORAGE_NODES => $STORAGE_VALUES){
    echo '
    <script type="text/javascript">
    google.charts.load("current", {"packages":["corechart"]});
    google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
          ["Key", "Value"],'."\n";
    foreach($STORAGE_VALUES as $CLIENT_VALUES){
        $USED_SPACE = explode(" ", $CLIENT_VALUES['used_space']);
        echo '["'.$CLIENT_VALUES['name'].' used space in GB",     '.$USED_SPACE[0].'],'."\n";
    }
        echo ']);

        var chart = new google.visualization.PieChart(document.getElementById("'.$STORAGE_NODES.'_clients"));

        var options = {
               "width": 400,
               "height": 400,
               "chartArea": {"width": "80%", "height": "80%"},
               "legend": {"position": "top"},
               is3D: true,
    };


        chart.draw(data, options);
      }
    </script>
';
}

?>
