<?php

$LOGRESULT = $mysqlconn->query("SELECT username,action,time FROM uilog ORDER BY id desc");
echo "<table><tr style='background-color: lightgreen;'><td>Time</td><td>Username</td><td>Action</td></tr>";
while ($row = $LOGRESULT->fetch_assoc()){
    echo "<tr style='background-color: lightgreen;'><td>$row[time]</td><td>$row[username]</td><td>$row[action]</td></tr>";
}
echo "</table>";
?>
