<?php
$FILTERS = "<table style='border: 1px solid black; background-color: lightblue;'><tr><td>Filters:</td><td></td></tr>";
foreach ($URI_ARRAY as $URI_ITEM) {
    $URI_ITEM = explode("---", $URI_ITEM);
    if ($URI_ITEM[0] == "jobtype"){
        $TYPE_FILTER = "and type='$URI_ITEM[1]'";
        $REMOVEDFILTERURL = str_replace("/$URI_ITEM[0]---$URI_ITEM[1]", "", $FULLURL);
        $FILTERS .= "<tr><td>type = $URI_ITEM[1]</td><td><a href='$REMOVEDFILTERURL'>[Remove]</a></td></tr>";
        $JOBTYPE = $URI_ITEM[1];
    }
    if ($URI_ITEM[0] == "statusfilter"){
        $STATUS_FILTER = "and status='$URI_ITEM[1]'";
        $REMOVEDFILTERURL = str_replace("/$URI_ITEM[0]---$URI_ITEM[1]", "", $FULLURL);
        $FILTERS .= "<tr><td>status = $URI_ITEM[1]</td><td><a href='$REMOVEDFILTERURL'>[Remove]</a></td></tr>";
        $STATUSFILTER = $URI_ITEM[1];
    }
    if ($URI_ITEM[0] == "storagenode"){
        $STATUS_FILTER = "and storage_node='$URI_ITEM[1]'";
        $REMOVEDFILTERURL = str_replace("/$URI_ITEM[0]---$URI_ITEM[1]", "", $FULLURL);
        $FILTERS .= "<tr><td>storage node = $URI_ITEM[1]</td><td><a href='$REMOVEDFILTERURL'>[Remove]</a></td></tr>";
        $STORAGENODE = $URI_ITEM[1];
    }
    if ($URI_ITEM[0] == "dataset"){
        $STATUS_FILTER = "and dataset LIKE '$URI_ITEM[1]:%'";
        $REMOVEDFILTERURL = str_replace("/$URI_ITEM[0]---$URI_ITEM[1]", "", $FULLURL);
        $FILTERS .= "<tr><td>Dataset = $URI_ITEM[1]</td><td><a href='$REMOVEDFILTERURL'>[Remove]</a></td></tr>";
        $STORAGENODE = $URI_ITEM[1];
    }
    if ($URI_ITEM[0] == "pagenum"){
        $PAGENUM = $URI_ITEM[1];
    }
    if (!isset($PAGENUM)){
        $PAGENUM = 1;
    }
}

foreach ($URI_ARRAY as $URI_ITEM) {
    $URI_ITEM = explode("---", $URI_ITEM);
    if ($URI_ITEM[0] == "queuelimit"){
        $START = ($PAGENUM*$URI_ITEM[1])-$URI_ITEM[1];
        $QUEUE_LIMIT = "LIMIT $START,$URI_ITEM[1]";
        $QUEUELIMIT_NUMBER = $URI_ITEM[1];
    }
}

if (!isset($QUEUE_LIMIT)){
    $START = ($PAGENUM*100)-100;
    $QUEUE_LIMIT = "LIMIT $START,100";
    $QUEUELIMIT_NUMBER = 100;
}

if ($PAGE == "client"){
    $CLIENT_QUERY=$mysqlconn->query("SELECT dataset FROM clients where id='$CLIENT'");
    $CLIENT_ROW = $CLIENT_QUERY->fetch_assoc();
    $CLIENT_FILTER = "and dataset='$CLIENT_ROW[dataset]'";
    $REMOVEDFILTERURL = str_replace("client/$CLIENT", "queue", $FULLURL);
    $FILTERS .= "<tr><td>client id = $CLIENT (dataset: $CLIENT_ROW[dataset])</td><td><a href='$REMOVEDFILTERURL'>[Remove]</a></td></tr>";
}

echo "<br/>\n";
if (isset($QUEUELIMIT_NUMBER)) { $QUEUELIMITURL = str_replace("/queuelimit---$QUEUELIMIT_NUMBER", "", $FULLURL);}else{ $QUEUELIMITURL = $FULLURL;}
echo "Results per page: <a href='$QUEUELIMITURL/queuelimit---20'>20</a> | <a href='$QUEUELIMITURL/queuelimit---50'>50</a> | <a href='$QUEUELIMITURL/queuelimit---100'>100</a>";

echo "<br/>\n";

$FILTERS .= "</table>\n";

echo "Results per page: $QUEUELIMIT_NUMBER<br/>\n";
echo "<br/>\n$FILTERS\n<br/>";

include ('verification_status.php');
include ('queue_next_client.php');

$CLIENTS = $mysqlconn->query("SELECT hostname,dataset,friendly_name FROM clients");
while($row = $CLIENTS->fetch_assoc()) {
    $hostname = $row["hostname"];
    $dataset = explode(":", $row['dataset']);
    $client_hostname = $hostname."_".$dataset[0].":".$dataset[1];
    $CLIENTS_ARRAY[$client_hostname] = $row["friendly_name"];
}

if (!isset($TYPE_FILTER)){$TYPE_FILTER="";}
if (!isset($CLIENT_FILTER)){$CLIENT_FILTER="";}
if (!isset($STATUS_FILTER)){$STATUS_FILTER="";}

$QUEUE = $mysqlconn->query("SELECT * FROM queue WHERE id!='' $TYPE_FILTER $CLIENT_FILTER $STATUS_FILTER ORDER BY id DESC $QUEUE_LIMIT");
$ROWS = $QUEUE->num_rows;
if ($ROWS > 0) {
    echo "<table border=0><tr><td>ID</td><td>Dataset</td><td>Friendly Name</td><td>Type</td><td>Storage Node</td><td>Scheduled</td><td>Started</td><td>Ended</td><td>Total Time</td><td>Status</td><td>Logs</td><td>Actions</td></tr>\n";
    $total_time_array = array();
    $graph = array();
    $nodes = array();
    while($row = $QUEUE->fetch_assoc()) {
        $CLIENT_QUERY=$mysqlconn->query("SELECT id FROM clients where hostname='$row[hostname]' and dataset='$row[dataset]'");
        $CLIENT_ROW = $CLIENT_QUERY->fetch_assoc();
        $hostname = $row["hostname"];
	    $dataset = explode(":", $row["dataset"]);
	    $friendly_name_client = $hostname."_".$dataset[0].":".$dataset[1];
        $friendly_name = $CLIENTS_ARRAY[$friendly_name_client];
        $friendly_name_short = explode (" ", $friendly_name);
        if (!in_array($row['storage_node'], $nodes)){
            array_push($nodes, $row['storage_node']);
        }
        if ($row["status"] == "Success"){
            $row_bgcolor = "lightgreen";
            $ended = true;
            $running = false;
        }elseif ($row["status"] == "Failed"){
            $row_bgcolor = "#FA8072";
            $ended = true;
            $running = false;
        }elseif ($row["status"] == "Started"){
            $row_bgcolor = "lightblue";
            $running = true;
            $ended = false;
        }elseif ($row["status"] == "Scheduled"){
            $row_bgcolor = "orange";
            $running = false;
            $ended = false;
        }else{
            $ended = false;
            $running = false;
        }
        echo "<tr style='background-color: $row_bgcolor;'>\n";
        echo "<td>" . $row["id"] . "</td>\n";
        $HOSTNAMEURL = str_replace ($URL.$BASEURI."queue", $URL.$BASEURI."client/$CLIENT_ROW[id]", $FULLURL);
	    echo "<td><a href='".$HOSTNAMEURL."'>" . $dataset[0] . ":" . $dataset[1] . "</td>\n";
        echo "<td><a href='".$HOSTNAMEURL."'>" . $friendly_name . "</td>\n";
        if (isset($JOBTYPE)) { $JOBTYPEURL = str_replace ("/jobtype---$JOBTYPE", "", $FULLURL); }else{ $JOBTYPEURL = $FULLURL;}
        echo "<td><a href='".$JOBTYPEURL."/jobtype---$row[type]'>" . $row["type"] . "</a></td>\n";
        if (isset($STORAGENODE)) { $STORAGENODEURL = str_replace ("/storagenode---$STORAGENODE", "", $FULLURL); } else{ $STORAGENODEURL = $FULLURL;}
        echo "<td><a href='".$STORAGENODEURL."/storagenode---$row[storage_node]'>" . $row["storage_node"] . "</a></td>\n";
	    echo "<td>" . $row["scheduled"] . "</a></td>\n";
	    if ($row["started"] == "0000-00-00 00:00:00"){
	        echo "<td>Not yet started</td>\n";
	    } else {
	        echo "<td>" . $row["started"] . "</td>\n";
        }
	    if ($row["ended"] == "0000-00-00 00:00:00"){
            echo "<td>Not yet ended</td>\n";
        } else {
            echo "<td>" . $row["ended"] . "</td>\n";
        }
        if ($ended == true){
            $total_time = calculate_time_span ($row["ended"], $row["scheduled"]);
            echo "<td>Completed in " . $total_time[0] . "</td>\n";
            array_push($graph, ["$friendly_name_short[0]", "$row[started]", "$row[ended]", "$row[type]", $row['storage_node']]);
        }else{
            if (!$running){
                array_push($graph, ["$friendly_name_short[0]", "$row[scheduled]", "$row[ended]", "$row[type]", $row['storage_node']]);
                $now = date("Y-m-d H:i:s");
                $total_time = calculate_time_span ($now, $row["scheduled"]);
                echo "<td>Scheduled for ".$total_time[0]."</td>\n";
            }else{
                array_push($graph, ["$friendly_name_short[0]", "$row[started]", "$row[ended]", "$row[type]", $row['storage_node']]);
                $now = date("Y-m-d H:i:s");
                $total_time = calculate_time_span ($now, $row["started"]);
                echo "<td>Running for ".$total_time[0]."</td>\n";
            }
        }
        array_push($total_time_array, $total_time[1]);
        if (isset($STATUSFILTER)) {$STATUSFILTERURL = str_replace ("/statusfilter---$STATUSFILTER", "", $FULLURL); }else{ $STATUSFILTERURL = $FULLURL;}
        echo "<td><a href='".$STATUSFILTERURL."/statusfilter---$row[status]'>" . $row["status"] . "</a></td>\n";
        echo "<td><a href='".$URL.$BASEURI."log/".$row["id"]."'>View Logs</td>\n";

        # If the job is taking twice as much time as usual, display a warning, next to it.
        if ($row["status"] == "Started" or $row["status"] == "Scheduled"){
            $AVG_JOB_EXEC_RESULT = $mysqlconn->query("SELECT scheduled,started,ended FROM queue WHERE hostname='$row[hostname]' and type='$row[type]' and status='Success' ORDER BY id DESC LIMIT 10");
            $ROWS_AVG = $AVG_JOB_EXEC_RESULT->num_rows;
            if ($ROWS_AVG > 2){
                $time_seconds_avg = 0;
                while($avg_row = $AVG_JOB_EXEC_RESULT->fetch_assoc()) {
                    $time_seconds_avg  = (strtotime($avg_row['ended']) - strtotime($avg_row['scheduled']))+$time_seconds_avg;
                }
                $average_running_time = $time_seconds_avg/5;
                if ($total_time[1] > $average_running_time){ 
                    echo "<td><b>Job is taking much longer than usual!</b></td>\n";
                }
            }
            echo "<td><a href='".$URL.$BASEURI."kill/$row[id]'>Kill</a></td>\n";
        }

        echo "</tr>\n";
    }

    # Statistics
    $time_elements = count($total_time_array);
    $time_seconds = 0;
    foreach ($total_time_array as $key => $value){
        $time_seconds = $value+$time_seconds;
    }
    $avg_time_seconds = $time_seconds/$time_elements;
    $avg_time = sprintf('%02d:%02d:%02d', ($avg_time_seconds/3600),($avg_time_seconds/60%60), $avg_time_seconds%60);
    $total_time = sprintf('%02d:%02d:%02d', ($time_seconds/3600),($time_seconds/60%60), $time_seconds%60);
    echo "<tr><td align='right' style='background-color: lightblue;' colspan=8>Average Time</td><td style='background-color: lightblue;' colspan=3>$avg_time</td></tr>\n";
    echo "<tr><td align='right' style='background-color: lightblue;' colspan=8>Total Time</td><td style='background-color: lightblue;' colspan=3>$total_time</td></tr>\n";
    echo "</table>\n";
} else {
    echo "0 clients found";
}

echo "<br/>\n";
include ('pagination.php');

echo "<br/><br/>\n";

include ('queue_graph.php');
?>
