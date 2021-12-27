<?php

echo "<form method='post'>";
echo "<table style='border: 1px solid black'>";
echo "<tr><td width='300' align='right'>Backupator ID:</td><td><font color=red>*</font></td><td width='400'><input type='text' name='hostname' value='$_POST[hostname]' size='60'></td><td><font color='red'>$form_errors[form_hostname]</font><span class='tooltip'>(?)<span class='tooltiptext'>Can be taken from /opt/backupator/etc/backupator.conf STORAGE_NODE_ID</span></span></td></tr>";

echo "<tr><td width='200' align='right'>Backupator IP address:</td><td><font color=red>*</font></td><td width='400'><input type='text' name='ip' value='$_POST[ip]' size='60'></td><td><font color='red'>$form_errors[form_ip]</font><span class='tooltip'>(?)<span class='tooltiptext'>Can be obtained with:<br/>ip a</span></span></td></tr>";

echo "<tr><td width='200' align='right'>Root ZFS dataset (example mypool/backup):</td><td><font color=red>*</font></td><td width='400'><input type='text' name='pool' value='$_POST[pool]' size='60'></td><td><font color='red'>$form_errors[form_pool]</font><span class='tooltip'>(?)<span class='tooltiptext'>You can see your pools and datasets with:<br/>zpool list<br/>zfs list</span></span></td></tr>";

echo "<tr><td width='200' align='right'>Storage Path:</td><td><font color=red>*</font></td><td width='400'><input type='text' name='storage_path' value='$_POST[storage_path]' size='60'></td><td><font color='red'>$form_errors[form_storage_path]</font><span class='tooltip'>(?)<span class='tooltiptext'>The path where the root dataset is mounted, it can be obtained with:<br/>zfs get mountpoint YOUR_ROOT_DATASET</span></span></td></tr>";

echo "<tr><td width='200' align='right'></td><td></td><td width='400'><input type='submit' value='Add Storage Node'></td></tr>";
echo "</table>";
echo "</form>";

?>
