<?php

$QUEUE = $mysqlconn->query("SELECT * FROM queue WHERE id!='' $TYPE_FILTER $CLIENT_FILTER $STATUS_FILTER ORDER BY id DESC");
$ROWS = $QUEUE->num_rows;

$PAGES = explode(".", $ROWS/$QUEUELIMIT_NUMBER);
if (isset($PAGES[1])){
    $PAGES = $PAGES[0]+1;
}else{
    $PAGES = $PAGES[0];
}

foreach ($URI_ARRAY as $URI_ITEM) {
    $URI_ITEM = explode("---", $URI_ITEM);
    if ($URI_ITEM[0] == "pagenum"){
        $CURRENT_PAGE = $URI_ITEM[1];
    }
    if (!isset($CURRENT_PAGE)){
        $CURRENT_PAGE = 1;
    }
}

$PAGEURL = str_replace ("/pagenum---$CURRENT_PAGE", "", $FULLURL);

echo "Total Jobs: $ROWS<br/>Total Pages: $PAGES<br/>\n";
if ($CURRENT_PAGE > 10){
    echo "<a href=$PAGEURL>1</a> ... \n";
}
for ($PAGENUM = 1; $PAGENUM <= $PAGES; $PAGENUM++){
    if ($PAGENUM < $CURRENT_PAGE + 10 and $PAGENUM > $CURRENT_PAGE - 10){
        if ($PAGENUM == $CURRENT_PAGE){
            echo " <font style='color: red;'>[$PAGENUM]</font> ";
        }else{
            echo "<a href='$PAGEURL/pagenum---$PAGENUM'>$PAGENUM</a> \n";
        }
    }
}

if ($CURRENT_PAGE < $PAGES-9){
echo " ... <a href=$PAGEURL/pagenum---$PAGES>$PAGES</a>";
}

?>
