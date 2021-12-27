<?php

if (isset($CLIENT) and isset($ACTION)){

    # Activation of client
    if ($ACTION == "activate"){
        $mysqlconn->query("UPDATE clients SET active='1' WHERE id='$CLIENT'");
    $mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Activated client ID: $CLIENT', SYSDATE())");
    $REFRESHURL = str_replace("/activate", "", $FULLURL);
    echo "<meta http-equiv='refresh' content='0; url=$REFRESHURL'>";
    }

    # Deactivation of client
    if ($ACTION == "deactivate"){
        $mysqlconn->query("UPDATE clients SET active='0' WHERE id='$CLIENT'");
    $mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Deactivated client ID: $CLIENT', SYSDATE())");
        $REFRESHURL = str_replace("/deactivate", "", $FULLURL);
        echo "<meta http-equiv='refresh' content='0; url=$REFRESHURL'>";
    }

    # Manual backup start
    if ($ACTION == "backupstart"){
        $STORAGE_QUERY = $mysqlconn->query("SELECT storage FROM clients WHERE id='$CLIENT'");
        $STORAGE_RESULT = $STORAGE_QUERY->fetch_assoc();
    $QUEUE_CHECK = $mysqlconn->query("SELECT * FROM queue WHERE storage_node='$STORAGE_RESULT[storage]' and ended=0");
        if ($QUEUE_CHECK->num_rows > 0 and $CONFIRM == "" ) {
            echo "<span style='color: red;'>There are other tasks running, please confirm the start of the backup for client ID $CLIENT</span>
            <a href='$FULLURL/CONFIRM'><input type='button' value='CONFIRM' /></a><br/><br/>";
        }else{
            $CLIENT_QUERY = $mysqlconn->query("SELECT hostname,storage,dataset FROM clients WHERE id='$CLIENT'");
        $CLIENT_RESULT = $CLIENT_QUERY->fetch_assoc();
            $mysqlconn->query("INSERT INTO queue (type, hostname, dataset, storage_node, scheduled, status) VALUES ('backup', '$CLIENT_RESULT[hostname]', '$CLIENT_RESULT[dataset]', '$CLIENT_RESULT[storage]', SYSDATE(), 'Scheduled')");
            $mysqlconn->query("UPDATE clients SET lastrun=SYSDATE() WHERE id='$CLIENT'");
        $mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Start manual backup for client id $CLIENT', SYSDATE())");
        $REFRESHURL = str_replace("/backupstart", "", $FULLURL);
            $REFRESHURL = str_replace("/CONFIRM", "", $REFRESHURL);
            echo "<meta http-equiv='refresh' content='0; url=$REFRESHURL'>";
        }
    }

    # Manual verification start
    if ($ACTION == "verify"){
        $STORAGE_QUERY = $mysqlconn->query("SELECT storage FROM clients WHERE id='$CLIENT'");
        $STORAGE_RESULT = $STORAGE_QUERY->fetch_assoc();
        $QUEUE_CHECK = $mysqlconn->query("SELECT * FROM queue WHERE storage_node='$STORAGE_RESULT[storage]' and ended=0");
    if ($QUEUE_CHECK->num_rows > 0 and $CONFIRM == "" ) {
            echo "<span style='color: red;'>There are other tasks running, please confirm the start of the backup verification for client id $CLIENT</span>
            <a href='$FULLURL/CONFIRM'><input type='button' value='CONFIRM' /></a><br/><br/>";
        }else{
            $CLIENT_QUERY = $mysqlconn->query("SELECT hostname,storage,dataset FROM clients WHERE id='$CLIENT'");
            $CLIENT_RESULT = $CLIENT_QUERY->fetch_assoc();
            $mysqlconn->query("INSERT INTO queue (type, hostname, dataset, storage_node, scheduled, status) VALUES ('verify', '$CLIENT_RESULT[hostname]', '$CLIENT_RESULT[dataset]', '$CLIENT_RESULT[storage]', SYSDATE(), 'Scheduled')");
        $mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Schedule manual verification for client id $CLIENT', SYSDATE())");
            $REFRESHURL = str_replace("/verify", "", $FULLURL);
            $REFRESHURL = str_replace("/CONFIRM", "", $REFRESHURL);
            echo "<meta http-equiv='refresh' content='0; url=$REFRESHURL'>";
        }
    }

    # Manually schedule the client next by just changing the last run time
    if ($ACTION == "backupschedule"){
        $mysqlconn->query("UPDATE clients SET lastrun=0 WHERE id='$CLIENT'");
    $mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Schedule manual backup for iclient id $CLIENT', SYSDATE())");
        $REFRESHURL = str_replace("/backupschedule", "", $FULLURL);
        $REFRESHURL = str_replace("/CONFIRM", "", $REFRESHURL);
        echo "<meta http-equiv='refresh' content='0; url=$REFRESHURL'>";
    }
}
?>
