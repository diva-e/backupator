<?php

if (isset($_POST['submit'])){
    $ERRORS = "";
    foreach ($_POST as $key => $value){
        if ($key != 'submit'){
            if (preg_replace("/[0-9]+/", "", $value) != ""){
                $ERRORS .= "<b>$key</b> should be numeric only. The value that you set <b>$value</b> is not accepted!<br/>";
            }
        }
    }
    if ($ERRORS == ""){
        foreach ($_POST as $key => $value){
            if ($key != 'submit'){
                $OLDVALUE_RESOURCE = $mysqlconn->query("SELECT configvalue FROM config WHERE configkey='$key'");
                $row = $OLDVALUE_RESOURCE->fetch_assoc();
                if ($value != $row['configvalue']){
                    $mysqlconn->query("UPDATE config SET configvalue='$value' WHERE configkey='$key'");
                    $mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Changed config $key from $row[configvalue] to $value', SYSDATE())");
                }
            }
        }
        echo "<font color=green><b>Settings successfully updated</b></font><br/>";
    }else{
        echo "<font color=red>".$ERRORS."</font>";
    }
echo "<br/>";
}

$CONFIG = $mysqlconn->query("SELECT * FROM config ORDER BY id");
echo "<form action='$FULLURL' method='post'><table><tr><td>Config Key</td><td>Config Value</td><td>Description</td></tr>";
while($row = $CONFIG->fetch_assoc()) {
    echo "<tr><td>$row[configkey]</td><td><input type='text' name='$row[configkey]' value='$row[configvalue]' /></td><td>$row[description]</td></tr>";
}
echo "<tr><td></td><td><input type='submit' name='submit' value='Save' /></td></tr></table></form>";

?>
