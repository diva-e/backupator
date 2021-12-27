<?php

$items = count($graph);
$last_item = $items-1;
$start_time = $graph[$last_item][1];
$end_time = $graph[0][1];

#var_dump($nodes);
foreach ($nodes as $node){
    echo "$node";
    echo '
    <script type="text/javascript">
    google.charts.load("current", {"packages":["timeline"]});
    google.charts.setOnLoadCallback(drawChart);
    function drawChart() {
        var container = document.getElementById("'.$node.'");
        var chart = new google.visualization.Timeline(container);
        var dataTable = new google.visualization.DataTable();

        dataTable.addColumn({ type: "string", id: "hours" });
        dataTable.addColumn({ type: "string", id: "Bar Label" });
        dataTable.addColumn({ type: "date", id: "Star" });
        dataTable.addColumn({ type: "date", id: "End" });
        dataTable.addRows(['."\n";
        $i = 0;
            foreach ($graph as $key => $value){
            $storage_node = $value[4];
                if ($storage_node == $node){
                    $hostname = $value[0];
                    $scheduled = $value[1];
                    if ($value[2] == "0000-00-00 00:00:00"){
                        $ended = date("Y-m-d H:i:s");
                    }else{
                        $ended = $value[2];
                    }
                    $type = $value[3];
                    $start = explode(" ", $scheduled);
                    list ($start_year, $start_month, $start_day) = explode("-", $start[0]);
                    list ($start_hour, $start_minute, $start_sec) = explode(":", $start[1]);
                    $end = explode(" ", $ended);
                    list ($end_year, $end_month, $end_day) = explode("-", $end[0]);
                    list ($end_hour, $end_minute, $end_sec) = explode(":", $end[1]);
                    $start = "$start_year, $start_month, $start_day, $start_hour, $start_minute, $start_sec";
                    $end = "$end_year, $end_month, $end_day, $end_hour, $end_minute, $end_sec";
                    echo "[ '$type', '$hostname', new Date($start), new Date($end) ]";
                    if ( $i != $last_item){
                        echo ",\n";
                    }else{
                        echo "\n";
                    }
                    $i = $i+1;
                }
            }
        echo ']);

        var options = {
        timeline: { height: "200px" }
        };

        chart.draw(dataTable, options);
      }
    </script>
    <div id="'.$node.'" style="height: 180px;"></div>
';
}

?>
