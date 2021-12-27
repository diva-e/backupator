<?php

if (isset($URI_ARRAY[1])){ $CLIENT = $URI_ARRAY[1];}
if (isset($URI_ARRAY[2])){ $ACTION = $URI_ARRAY[2];}
if (isset($URI_ARRAY[3])){ $CONFIRM = $URI_ARRAY[3];}

include ('client_actions.php');

if ($PAGE == "clients"){
    echo "+<a href='". $URL . $BASEURI ."addclient'>[Add new client]</a><br/><br/>";
}
if ($PAGE == "addclient"){
    include ('addclient_processing.php');
    include ('addclient_form.php');
    echo "<br/>";
}

if ($PAGE == "editclient"){
    include ('editclient_processing.php');
    include ('editclient_form.php');
    echo "<br/>";
}

include ('clients_sql.php');

?>
