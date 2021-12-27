<?php

$RESULT_IDLE_TIME = $mysqlconn->query("SELECT id,started,ended FROM queue WHERE storage_node='$hostname' and started > NOW() - interval 24 hour ORDER BY id ASC") or die($mysqlconn->error);
$IDLE_SECONDS=0;
for ($i = 1; $row_idle_time = $RESULT_IDLE_TIME->fetch_assoc(); $i++){
    if ($i == 1){
        $previous_ended = $row_idle_time['ended'];
        continue;
    }else{
#        echo $row_idle_time['id'] . " - " . strtotime($row_idle_time['started']) . " - " . strtotime($previous_ended)."<br/>";
        $IDLE_SECONDS = (strtotime($row_idle_time['started']) - strtotime($previous_ended)) + $IDLE_SECONDS;
        $previous_ended = $row_idle_time['ended'];
    }
}



?>
