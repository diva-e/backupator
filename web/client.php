<?php

echo "<meta http-equiv='refresh' content='10; url=$FULLURL'>\n";

if (isset($URI_ARRAY[1])){ $CLIENT = $URI_ARRAY[1];}
if (isset($URI_ARRAY[2])){ $ACTION = $URI_ARRAY[2];}
if (isset($URI_ARRAY[3])){ $CONFIRM = $URI_ARRAY[3];}

if (strlen($CLIENT) == 0){
    echo "<meta http-equiv='refresh' content='0; url=".$URL.$BASEURI."clients/'>";
}

include ('client_actions.php');

$CLIENT_RESULT = $mysqlconn->query("SELECT * FROM clients WHERE id='$CLIENT'");
if ($CLIENT_RESULT->num_rows > 0) {
    $row = $CLIENT_RESULT->fetch_assoc();
    $dataset = explode(":", $row['dataset']);
    echo "<table border=1><tr><td>ID</td><td>Hostname (Friendly Name)</td><td>Last Run</td><td>Storage Node</td><td>Verify Template</td><td>Status</td><td>Actions</td></tr><tr>\n";
    echo "<td>$row[id]</td>\n";
    echo "<td>$row[hostname] / $dataset[1] ($row[friendly_name])</td>\n";
    echo "<td>$row[lastrun]</td>\n";
    echo "<td>$row[storage]</td>\n";
    echo "<td>$row[verify_template]</td>\n";

    $ACTIVATE_URL = "$FULLURL"."/activate";
    $DEACTIVATE_URL = "$FULLURL"."/deactivate";
    $BACKUP_START_URL = "$FULLURL"."/backupstart";
    $BACKUP_SCHEDULE_URL = "$FULLURL"."/backupschedule";
    $VERIFY_URL = "$FULLURL"."/verify";

    if ($row["active"] == 1){
        echo "<td style='color: green;'>Active</td>\n";
        echo "<td><a href='$DEACTIVATE_URL'><input type='button' value='Deactivate' /></a>\n";
    }else{
        echo "<td style='color: red;'>Inactive</td>\n";
        echo "<td><a href='$ACTIVATE_URL'><input type='button' value='Activate' /></a>\n";
    }
    echo "<a href='$BACKUP_START_URL'><input type='button' value='Start Backup' ></a>\n";
    echo "<a href='$BACKUP_SCHEDULE_URL'><input type='button' value='Schedule Backup Next' ></a>\n";
    echo "<a href='$VERIFY_URL'><input type='button' value='Verification' ></a>\n";
    echo "</td>\n";
    echo "</tr></table>\n";
}else{
    echo "No such client $CLIENT<br/>\n";
}

echo "<br/>\n";

include ('queue_sql.php');
?>
