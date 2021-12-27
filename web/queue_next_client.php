<?php

echo "Next clients:<br/>";
$NODES = $mysqlconn->query("SELECT hostname,replication_enabled,active FROM storage_nodes");
echo "<table border=0>";
echo "<tr><td width='100'>Starts After</td><td width='100'>Dataset</td><td width='220'>Server</td><td width='200'>Friendly Name</td><td>Backup Start Time</td></tr>";
if ( $NODES->num_rows > "0" ){
    while ($row_node = $NODES->fetch_assoc()){
        $NEXT_CLIENT_RESULT = $mysqlconn->query("SELECT hostname,dataset,lastrun,backup_interval,friendly_name FROM clients WHERE active='1' and storage='$row_node[hostname]' ORDER BY lastrun");
        if ( $row_node['replication_enabled'] == 0 ){
            $replication = "<font color='red'>Replication is disabled</font>";
        } else {
            $replication = "<font color='green'>Replication is enabled</font>";
	}
        if ( $NEXT_CLIENT_RESULT->num_rows > "0" ){
            if ($row_node['active'] == '1' ){
                $node_color = 'green';
            } else {
                $node_color = 'red';
            }
            $clientlist = array();
	    while ($row = $NEXT_CLIENT_RESULT->fetch_assoc()){
	        $dataset = explode(":", $row['dataset']);
                $lastrun = DateTime::createFromFormat('Y-m-d H:i:s', $row['lastrun']);
                $lastrun_timestamp = $lastrun->getTimestamp();
                $next_run_timestamp = $lastrun_timestamp+($row['backup_interval']*60);
                array_push($clientlist, [$next_run_timestamp, $dataset, $row['friendly_name']]);
	    }
            asort($clientlist);
            $i=0;
            foreach ($clientlist as $value){
                $dataset = $value[1];
                $friendly_name = $value[2];
                $i = $i+1;
                $date_now = new DateTime();
                $date_now_formatted = $date_now->format('H:i:s Y-m-d');
                $date_now_timestamp = $date_now->format('U');
                $date_var = new DateTime();
                $next_run = $date_var->setTimestamp($value[0]);
                $next_run_formatted = $next_run->format('H:i:s Y-m-d');
                $remaining_time = calculate_time_span($next_run_formatted, $date_now_formatted);
                if ($remaining_time[1] < 0){
                   $remaining_time[0] = "00:00:00";
                }
                if ($i == '1'){
                    $font_weight = 'bold';
                    $color = 'green';
                } else {
                    $font_weight = 'normal';
                    $color = 'black';
                }
                if ($i == 1){
                    echo "<tr><td valign=top colspan=5><hr></td></tr>";
                    echo "<tr><td valign=top colspan=5><span style='color: $node_color'><a href='".$URL.$BASEURI."queue/storagenode---".$row_node['hostname']."'>$row_node[hostname]</a></span> / $replication</td><tr>";
                }
                echo "<tr><td style='font-weight: $font_weight; color: $color;'>$remaining_time[0]</td><td style='font-weight: $font_weight; color: $color;'>$dataset[0]</td><td style='font-weight: $font_weight; color: $color;'>$dataset[1]</td><td style='font-weight: $font_weight; color: $color;'>($friendly_name)</td><td style='font-weight: $font_weight; color: $color;'>$next_run_formatted</td></tr>";
                if ($i == 10){
                  break;
                }
            }
            echo "</td>";
            echo "</tr>";
        }
    }
} else {
    echo "<tr><td><h3><font color='red'>There are no active storage nodes !!!</font></h3></td></tr>";
}
echo "</table>";
echo "<br/>";
?>
