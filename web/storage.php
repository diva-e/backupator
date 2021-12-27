<?php

if (isset($URI_ARRAY[1])){ $STORAGE = $URI_ARRAY[1]; }
if (isset($URI_ARRAY[2])){ $ACTION = $URI_ARRAY[2]; }

include ('storage_actions.php');

if ($PAGE == "addstorage"){
    include ('addstorage_processing.php');
    include ('addstorage_form.php');
    echo "<br/>";
} else {
    echo "+<a href='". $URL . $BASEURI ."addstorage'>[Add storage]</a><br/><br/>";
}

$STORAGE_RESULT = $mysqlconn->query("SELECT * FROM storage_nodes");
if ($STORAGE_RESULT->num_rows > 0) {
    echo "<table border=1><tr>
    <td>ID</td>
    <td>Hostname</td>
    <td>Last Schedule</td>
    <td>Idle time last 24 hours</td>
    <td>Free / Used Space</td>
    <td>Clients Space Usage</td>
    <td>Actions</td>
    </tr>";
    $STORAGE_NUMBERS = array();
    $CLIENT_NUMBERS = array();
    while ($row = $STORAGE_RESULT->fetch_assoc()){
        $hostname = $row['hostname'];
        include ('storage_idle_time.php');
        $color = dechex(rand(0x000000, 0xFFFFFF));
        array_push($STORAGE_NUMBERS, ["name" => "$hostname", "used_space" => human_size("$row[used_space]", NULL), "free_space" => human_size("$row[free_space]", NULL)]);

        # Client stats for disk used
        $CLIENT_RESULT = $mysqlconn->query("SELECT hostname,backup_size,snapshots_size FROM clients WHERE storage='$hostname'");
        if ($CLIENT_RESULT->num_rows > 0) {
            $CLIENT_NUMBERS[$hostname] = array();
            while ($client = $CLIENT_RESULT->fetch_assoc()){
                $used_space = $client['backup_size']+$client['snapshots_size'];
                array_push($CLIENT_NUMBERS[$hostname], ["name" => "$client[hostname]", "used_space" => human_size($used_space, "GB")]);
	    }
	    $NOCLIENTS=false;
	} else {
            $NOCLIENTS=true;
	}

        echo "<tr><td>$row[id]</td>";
        echo "<td>$hostname</td>";
        echo "<td>$row[lastschedule]</td>";
        $IDLE_TIME = seconds_to_human_time($IDLE_SECONDS);
        echo "<td>". $IDLE_TIME['0'] . "</td>";
	echo "<td><div id='$row[hostname]_free_used' style='width: 400px; height: 400px;'></div></td>";
	if ($NOCLIENTS == false){
            echo "<td><div id='$row[hostname]_clients' style='width: 400px; height: 400px;'></div></td>";

            if ($row["replication_enabled"] == 1){
                $replication = "<a href='$PAGE/$hostname/deactivate_replication'><input type='button' value='Deactivate Replication' /></a>";
            }else{
                $replication = "<a href='$PAGE/$hostname/activate_replication'><input type='button' value='Activate Replication' /></a>";
            }

            if ($row["active"] == 1){
                $status = "<a href='$PAGE/$hostname/deactivate'><input type='button' value='Deactivate Node' /></a>";
           }else{
                $status = "<a href='$PAGE/$hostname/activate'><input type='button' value='Activate Node' /></a>";
            } 
            echo "<td>";
            echo $status;
            echo "<br/>";
            echo $replication;
	    echo "</td>";
	} else {
            echo "<td colspan='2'>Storage node has no clients</td>";
	}
        echo "</tr>";
    }
    echo "</table>";
}else{
    echo "No storage nodes exist<br/>";
}

include ('storage_graph.php');
include ('clients_graph.php');

?>

