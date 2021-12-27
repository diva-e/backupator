<?php

$BACKUP_NAME = $URI_ARRAY[1];

$LOG_REQUEST = $mysqlconn->query("SELECT hostname,node_results,client_results FROM backups WHERE backup_name='$BACKUP_NAME'");
if ($LOG_REQUEST->num_rows > 0) {
    $row = $LOG_REQUEST->fetch_assoc();
    if (strlen($row['node_results']) != 0 or strlen($row['client_results']) != 0){
        $CLIENT = str_replace ("\n", "<br/>", $row['client_results']);
        $CLIENT = str_replace ("^", "'", $CLIENT);
        $NODE = str_replace ("\n", "<br/>", $row['node_results']);
        $NODE = str_replace ("^", "'", $NODE);
    }else{
        $NODE = "No log yet, please wait for the job to finish.";
    }
    echo "Queries for the hostname " . $row['hostname'] . ", backup name: " . $BACKUP_NAME . "<br/><br/>";
    echo "<table border=0 style='background-color: lightblue;'><tr><td>Node Results</td><td>Client Results</td></tr>";
    echo "<td valign='top'>$NODE</td><td valign='top'>$CLIENT</td>";
    echo "</tr>\n";
    echo "</table>";
} else {
    echo "No log entries for backup name: " . $BACKUP_NAME ;
}

?>
