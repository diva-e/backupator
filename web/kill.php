<?php

if (isset($URI_ARRAY[1])){
    if (isset($URI_ARRAY[2])){
        $QUEUE_ID = $URI_ARRAY[1];
        $mysqlconn->query("UPDATE queue SET ended=SYSDATE(), status='Failed', comment='Manually Killed' WHERE id='$QUEUE_ID'");
        $mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Killed task: $QUEUE_ID', SYSDATE())");
        echo "<meta http-equiv='refresh' content='0; url=".$URL.$BASEURI."queue'>";
    }else{
        echo "Please confirm the cancellation of the job $URI_ARRAY[1] [<a href='$FULLURL/confirm'>yes</a>] / [<a href='$_SERVER[HTTP_REFERER]'>no</a>]";
    }
}

?>
