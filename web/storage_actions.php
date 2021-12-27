<?php
if (isset($STORAGE) and isset($ACTION)){
    # Activation of storage node
    if ($ACTION == "activate"){
        $mysqlconn->query("UPDATE storage_nodes SET active='1' WHERE hostname='$STORAGE'");
	$mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Activated storage: $STORAGE', SYSDATE())");
	echo "<meta http-equiv='refresh' content='0; url=".$URL.$BASEURI."storage'>";
    }

    # Deactivation of client
    if ($ACTION == "deactivate"){
        $mysqlconn->query("UPDATE storage_nodes SET active='0' WHERE hostname='$STORAGE'");
	$mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Deactivated storage: $STORAGE', SYSDATE())");
	echo "<meta http-equiv='refresh' content='0; url=".$URL.$BASEURI."storage'>";
    }

    # Activation of replication
    if ($ACTION == "activate_replication"){
        $mysqlconn->query("UPDATE storage_nodes SET replication_enabled='1' WHERE hostname='$STORAGE'");
	$mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Activated replication: $STORAGE', SYSDATE())");
	echo "<meta http-equiv='refresh' content='0; url=".$URL.$BASEURI."storage'>";
    }

    # Deactivation of replication
    if ($ACTION == "deactivate_replication"){
        $mysqlconn->query("UPDATE storage_nodes SET replication_enabled='0' WHERE hostname='$STORAGE'");
	$mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Deactivated replication: $STORAGE', SYSDATE())");
	echo "<meta http-equiv='refresh' content='0; url=".$URL.$BASEURI."storage'>";
    }
}
?>
