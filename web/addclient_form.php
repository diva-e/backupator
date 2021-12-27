<?php

echo "<form method='post'>";
echo "<table style='border: 1px solid black'>";
echo "<tr><td width='300' align='right'>Hostname (where the dataset resides):</td><td><font color=red>*</font></td><td width='400'><input type='text' name='hostname' value='$_POST[hostname]' size='60'></td><td><font color='red'>$form_errors[form_hostname]</font><span class='tooltip'>(?)<span class='tooltiptext'>This is the host where the dataset resides, can be different than the host which is using it, for example if you have a host where you spawn multiple virtual machines or linux containers</span></span></td></tr>";

echo "<tr><td width='200' align='right'>Name (example: jiraserver):</td><td><font color=red>*</font></td><td width='400'><input type='text' name='friendly_name' value='$_POST[friendly_name]' size='60'></td><td><font color='red'>$form_errors[form_friendly_name]</font></td></tr>";

if ($form_type == 'mysql'){
  $selected_form_type_mysql = 'selected';
}
if ($form_type == 'clickhouse'){
  $selected_form_type_clickhouse = 'selected';
}
if ($form_type == 'os'){
  $selected_form_type_os = 'selected';
}
if ($form_type == 'data'){
  $selected_form_type_data = 'selected';
}
if ($form_type == 'lxc_configs'){
  $selected_form_type_lxc_configs = 'selected';
}
if ($form_type == 'vm_configs'){
  $selected_form_type_vm_configs = 'selected';
}
echo "<tr><td width='200' align='right'>Type:</td><td><font color=red>*</font></td><td width='400'><select name='type' style='width: 370px;'>";
echo "<option value=''>--- Select ---</option>";
echo "<option value='mysql' $selected_form_type_mysql>MySQL</option>";
echo "<option value='clickhouse' $selected_form_type_clickhouse>Clickhouse</option>";
echo "<option value='os' $selected_form_type_os>Operating System</option>";
echo "<option value='data' $selected_form_type_data>Data</option>";
echo "<option value='lxc_configs' $selected_form_type_lxc_configs>LXC Configs directory</option>";
echo "<option value='vm_configs' $selected_form_type_vm_configs>VM Configs directory</option>";
echo "</td><td><font color='red'>$form_errors[form_type]</font></td></tr>";

if ($form_destination == 'dataset'){
  $selected_form_destination_dataset = 'selected';
}
if ($form_destination == 'zvol'){
  $selected_form_destination_zvol = 'selected';
}
echo "<tr><td width='200' align='right'>Source/Destination:</td><td><font color=red>*</font></td><td width='400'><select name='destination' style='width: 370px;'>";
echo "<option value=''>--- Select ---</option>";
echo "<option value='dataset' $selected_form_destination_dataset>Dataset</option>";
echo "<option value='zvol' $selected_form_destination_zvol>Zvol</option>";
echo "</td><td><font color='red'>$form_errors[form_type]</font></td></tr>";

echo "<tr><td width='200' align='right'>Client hostname:</td><td><font color=red>*</font></td><td width='400'><input type='text' name='client' value='$_POST[client]' size='60'></td><td><font color='red'>$form_errors[form_client]</font></td></tr>";

echo "<tr><td width='200' align='right'>Dataset:</td><td><font color=red>*</font></td><td width='400'><input type='text' name='dataset' value='$_POST[dataset]' size='60'></td><td><font color='red'>$form_errors[form_dataset]</font></td></tr>";

if ($form_fstype == 'zfs'){
  $selected_form_fstype_zfs = 'selected';
}
if ($form_fstype == 'ext4'){
  $selected_form_fstype_ext4 = 'selected';
}
echo "<tr><td width='200' align='right'>Filesystem Type:</td><td><font color=red>*</font></td><td width='400'><select name='fstype' style='width: 370px;'>";
echo "<option value=''>--- Select ---</option>";
echo "<option value='zfs' $selected_form_fstype_zfs>ZFS</option>";
echo "<option value='ext4' $selected_form_fstype_ext4>Ext4</option>";
echo "</td><td><font color='red'>$form_errors[form_fstype]</font></td></tr>";

echo "<tr><td width='200' align='right'>Storage Node:</td><td><font color=red>*</font></td><td width='400'><select name='storage' style='width: 370px;'>";
echo "<option value=''>--- Select ---</option>";
$STORAGE_NODES = $mysqlconn->query("SELECT hostname FROM storage_nodes");
for($i = 1; $row = $STORAGE_NODES->fetch_assoc(); $i++) {
  if ($form_storage == $row['hostname']){
    echo "<option value='$row[hostname]' selected>$row[hostname]</option>";
  } else {
    echo "<option value='$row[hostname]'>$row[hostname]</option>";
  }
}
echo "</td><td><font color='red'>$form_errors[form_storage]</font></td></tr>";

echo "<tr><td width='200' align='right'>Backup Interval (Minutes):</td><td><font color=red>*</font></td><td width='400'><input type='text' name='backup_interval' value='$_POST[backup_interval]' size='60'></td><td><font color='red'>$form_errors[form_backup_interval]</font></td></tr>";

echo "<tr><td width='200' align='right'>Snapshot Retention (Days):</td><td><font color=red>*</font></td><td width='400'><input type='text' name='snapshot_retention' value='$_POST[snapshot_retention]' size='60'></td><td><font color='red'>$form_errors[form_snapshot_retention]</font></td></tr>";

echo "<tr><td width='200' align='right'>Geo Replicator:</td><td></td><td width='400'><select name='replicator' style='width: 370px;'>";
echo "<option value=''>--- Select ---</option>";
$STORAGE_NODES = $mysqlconn->query("SELECT hostname FROM storage_nodes");
for($i = 1; $row = $STORAGE_NODES->fetch_assoc(); $i++) {
  if ($form_replicator == $row['hostname']){
    echo "<option value='$row[hostname]' selected>$row[hostname]</option>";
  } else {
    echo "<option value='$row[hostname]'>$row[hostname]</option>";
  }
}
echo "</td></tr>";

if ($form_verifications == '1'){
  $selected_form_verify_enabled = 'selected';
}
if ($form_verifications == '0'){
  $selected_form_verify_disabled = 'selected';
}
echo "<tr><td width='200' align='right'>Perform Verifications:</td><td><font color=red>*</font></td><td width='400'><select name='verifications' style='width: 370px;'>";
echo "<option value=''>--- Select ---</option>";
echo "<option value='1' $selected_form_verify_enabled>Enabled</option>";
echo "<option value='0' $selected_form_verify_disabled>Disabled</option>";
echo "</td><td></td></tr>";

echo "<tr><td width='200' align='right'>Backup Verify Template:</td><td></td><td width='400'><select name='verify_template' style='width: 370px;'>";
echo "<option value=''>--- Select ---</option>";
$VERIFY_TEMPLATES = $mysqlconn->query("SELECT DISTINCT template FROM verify_queries ");
for($i = 1; $row = $VERIFY_TEMPLATES->fetch_assoc(); $i++) {
  if ($form_verify_template == $row['template']){
    echo "<option value='$row[template]' selected>$row[template]</option>";
  } else {
    echo "<option value='$row[template]'>$row[template]</option>";
  }
}
echo "</td></tr>";

echo "<tr><td width='200' align='right'>Backup Verify Config:</td><td></td><td width='400'><select name='backup_verify_config' style='width: 370px;'>";
echo "<option value=''>--- Select ---</option>";
$VERIFY_CONFIGS = $mysqlconn->query("SELECT name FROM backup_verify_configs");
for($i = 1; $row = $VERIFY_CONFIGS->fetch_assoc(); $i++) {
  if ($form_backup_verify_config == $row['name']){
    echo "<option value='$row[name]' selected>$row[name]</option>";
  } else {
    echo "<option value='$row[name]'>$row[name]</option>";
  }
}
echo "</td></tr>";


echo "<tr><td width='200' align='right'></td><td></td><td width='400'><input type='submit' value='Add Client'></td></tr>";
echo "</table>";
echo "</form>";

?>
