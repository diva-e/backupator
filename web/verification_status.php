<?php

$CONFIG = $mysqlconn->query("SELECT configvalue FROM config WHERE configkey='VERIFICATION_ENABLED'");
$row = $CONFIG->fetch_assoc();
if ($row['configvalue'] == '1'){
    echo "<h4><font color=green>Verifications are Enabled</font></h4>";
}else{
    echo "<h1><font color=red><b>Verifications are Disabled!!!</b></font></h1>";
}


?>
