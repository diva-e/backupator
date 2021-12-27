<?php

$LOG_ID = $URI_ARRAY[1];

$LOG_REQUEST = $mysqlconn->query("SELECT hostname,dataset,comment FROM queue where id='$LOG_ID'");
if ($LOG_REQUEST->num_rows > 0) {
    $row = $LOG_REQUEST->fetch_assoc();
    if (strlen($row['comment']) != 0){
        $LOG = str_replace ("\n", "<br/>", $row['comment']);
        $LOG = str_replace ("^", "'", $LOG);
    }else{
        $LOG = "No log yet, please wait for the job to finish.";
    }
    $dataset = explode(":", $row['dataset']);
    echo "Log entry for " . $dataset[0] . ":" . $dataset[1] . ", job ID: " . $LOG_ID . "<br/><br/>";
    echo "<table border=0 style='background-color: lightblue;'><tr><td width=100%>" . $LOG;
    echo "</td>\n</tr>\n";
    echo "</table>";
} else {
    echo "No log entries for queue ID: $LOG_ID";
}

?>
