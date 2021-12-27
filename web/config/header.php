<?php

$DBNAME='backupator_database';
$DBUSER='user';
$DBPASS='pass';
$DBHOST='192.168.2.133';
$DBPORT='3309';
$BASEURI='/backupator/';
$TITLE="";

include ('functions.php');

$mysqlconn = mysqli_init();
$mysqlconn->options(MYSQLI_OPT_CONNECT_TIMEOUT, 5);
if (!$mysqlconn->real_connect($DBHOST, $DBUSER, $DBPASS, $DBNAME, $DBPORT)){
  die('Unable to connect to the database!');
}

$URL = $_SERVER['REQUEST_SCHEME']."://".$_SERVER['SERVER_NAME'];
$URI = preg_replace('/' . str_replace('/', '\/',$BASEURI) . '/', '', $_SERVER['REQUEST_URI'], 1);
$URI_ARRAY = explode("/", $URI);
$PAGE = $URI_ARRAY[0];
$FULLURL = $URL.$BASEURI.$URI;

echo "<!DOCTYPE html>\n";
echo "<html>\n";
echo "<head>\n";
echo "<link rel='icon' type='image/png' href='".$URL.$BASEURI."backupator.ico'>";
echo "<title>".$TITLE."</title>\n";
echo "<link rel='stylesheet' type='text/css' href='".$URL.$BASEURI."css/general.css'>\n";
echo "<script type='text/javascript' src='".$URL.$BASEURI."js/google_charts.js'></script>";
echo "</head>\n";
echo "<body>\n";

?>
