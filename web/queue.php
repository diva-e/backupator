<?php

echo "<meta http-equiv='refresh' content='10; url=$FULLURL'>\n";

if (isset($URI_ARRAY[1])){ $CLIENT = $URI_ARRAY[1];}
if (isset($URI_ARRAY[2])){ $DATASET = explode("dataset---", $URI_ARRAY[2]); $DATASET = $DATASET[1];}
if (isset($URI_ARRAY[3])){ $ACTION = $URI_ARRAY[3];}
if (isset($URI_ARRAY[4])){ $CONFIRM = $URI_ARRAY[4];}

include ('client_actions.php');

include ('queue_sql.php');

?>
