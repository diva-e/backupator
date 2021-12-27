<?php
$CLIENTS = $mysqlconn->query("SELECT * FROM clients ORDER BY active DESC, lastrun ASC");
if ($CLIENTS->num_rows > 0) {
    echo "<table><tr style='background-color: #E1E1E1'>";
    echo "<td>Hostname</td>";
    echo "<td>Friendly Name</td>";
    echo "<td>FS Type</td>";
    echo "<td>Last Run</td>";
    echo "<td>Backup Size</td>";
    echo "<td>Snapshots Size</td>";
    echo "<td>Total Size</td>";
    echo "<td>Actions</td></tr>\n";
    $total_backups=0;
    $total_snapshots=0;
    $total_total=0;
    for($i = 1; $row = $CLIENTS->fetch_assoc(); $i++) {
        $hostname=$row["hostname"];
        $client_id = $row['id'];
        $dataset = explode(":", $row['dataset']);
        if ($row["active"] == "1"){
            if ($row["verify"] != "1" and $dataset[0] == "mysql"){
                $row_color = "orange";
            } else {
                $row_color = "green";
            }
        }else{
            $row_color = "red";
        }
        $even_odd = $i/2;
        $even_odd = explode('.', $even_odd);
        if (count($even_odd) == "1"){
            $bgcolor = '#E1E1E1';
        }else{
            $bgcolor = '#G1G1G1';
        }
        $backup_size=human_size($row["backup_size"], NULL);
        $snapshots_size=human_size($row["snapshots_size"], NULL);
        $total_size = human_size($row["backup_size"]+$row["snapshots_size"], NULL);
        echo "<tr style='color: $row_color; background-color: $bgcolor'>\n";
        echo "<td><a href='".$URL.$BASEURI."client/".$client_id."'>" . $dataset[0] . ": " . $dataset[1] . "</td>\n";
        echo "<td>" . $row["friendly_name"] . "</td>\n";
        echo "<td>" . $row["fstype"] . "</td>\n";
        echo "<td>" . $row["lastrun"] . "</td>\n";
        echo "<td>" . $backup_size . "</td>\n";
        echo "<td>" . $snapshots_size . "</td>\n";
        echo "<td>" . $total_size . "</td>\n";
        echo "<td><a href='".$URL.$BASEURI."editclient/$client_id'><input type='button' value='Edit' /></a></td>\n";
        echo "</tr>\n";
        $total_backups=$total_backups+$row["backup_size"];
        $total_snapshots=$total_snapshots+$row["snapshots_size"];
        $total_total=$total_total+$row["backup_size"]+$row["snapshots_size"];
    }
echo "<tr><td colspan=4>Total clients: ".$CLIENTS->num_rows."</td><td>".human_size($total_backups, NULL)."</td><td>".human_size($total_snapshots, NULL)."</td><td>".human_size($total_total, NULL)."</td></tr>\n";
echo "</table>\n";
echo "<br/>
<table>
<tr><td>Legend:</td></tr>
<tr><td style='color: green;'>Client Enabled and has recommended settings</td></tr>
<tr><td style='color: orange;'>Client Enabled, dataset type is mysql and has verifications disabled</td></tr>
<tr><td style='color: red;'>Client Disabled</td></tr>
</table>
";
} else {
    echo "0 active clients found";
}

?>
