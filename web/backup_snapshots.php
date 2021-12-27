<?php

$now=time();

echo "<table><tr><td>Hostname</td><td>Backup Name</td><td>Backup Time</td><td>Status</td><td>Double Verify</td></tr>";
$config_query = $mysqlconn->query("SELECT hostname,dataset,snapshot_retention FROM clients ORDER BY hostname,dataset ASC");
while ($client_config = $config_query->fetch_assoc()) {
    $LOGRESULT = $mysqlconn->query("SELECT * FROM backups WHERE present='1' and hostname='$client_config[hostname]' and dataset='$client_config[dataset]' ORDER BY backup_name DESC");
    $printed_hosts = array();
    while ($row = $LOGRESULT->fetch_assoc()){
        $dataset = explode(":", $row['dataset']);
        $backup_name = str_replace("backupator_", "", $row['backup_name']);
        if ($row['status'] == "Success"){
            $verify_color = "lightgreen";
        }elseif ($row['status'] == "Failed"){
            $verify_color = "#FA8072";
        }else{
            $verify_color = "gray";
        }
    
        if (in_array($dataset[1], $printed_hosts)){
            $dataset[1] = "";
        }else{
            echo "<tr><td colspan='4' height='20'></td></tr>";
        }
    
        if ($row['client_results'] == $row['node_results']){
            $double_verify = "Equal Results";
            $dv_color = "lightgreen";
        }else{
            $double_verify = "Results are different";
            $dv_color = "#FA8072";
        }
        if ($row['status'] == ""){
            $status = "No Status";
        } else {
            $status = $row['status'];
        }
        $backup_time = getdate($backup_name);
        $backup_time_formated = "$backup_time[weekday] / $backup_time[mday] $backup_time[month] $backup_time[year] / $backup_time[hours]:$backup_time[minutes]:$backup_time[seconds]";
        echo "<tr style='background-color: lightblue;'><td>$dataset[1]</td><td>$row[backup_name]</td><td>$backup_time_formated</td>";
        echo "<td style='background-color: $verify_color;'><a href=".$URL.$BASEURI."log/$row[verify_queue_id]>$status</a></td>";
        echo "<td style='background-color: $dv_color;'><a href=".$URL.$BASEURI."double_verify/$row[backup_name]>$double_verify</a></td>";
        echo "</tr>";
        array_push($printed_hosts, $dataset[1]);
   }
}
echo "</table>";
?>
