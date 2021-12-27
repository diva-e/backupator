<?php
foreach ($STORAGE_NUMBERS as $VALUES){
    $STORAGE_NODE = $VALUES['name'];
    $USED_SPACE = explode(" ", $VALUES['used_space']);
    $FREE_SPACE = explode(" ", $VALUES['free_space']);
    echo '
    <script type="text/javascript">
      google.charts.load("current", {"packages":["corechart"]});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
          ["Key", "Value"],
          ["Used Space in '.$USED_SPACE[1].'",     '.$USED_SPACE[0].'],
          ["Free Space in '.$FREE_SPACE[1].'",    '.$FREE_SPACE[0].']
        ]);

        var chart = new google.visualization.PieChart(document.getElementById("'.$STORAGE_NODE.'_free_used"));

        var options = {
               "width": 400,
               "height": 400,
               "chartArea": {"width": "80%", "height": "80%"},
               "legend": {"position": "top"},
               "is3D": true,
               pieSliceText: "value",
    };


        chart.draw(data, options);
      }
    </script>
';
}
?>
