<?php

$ID = $URI_ARRAY[1];

$CLIENTS = $mysqlconn->query("SELECT * FROM clients WHERE id='$ID'");
while($row = $CLIENTS->fetch_assoc()) {

  if (count($_POST) == '0'){
    $form_hostname             = htmlspecialchars($row['hostname'],             ENT_QUOTES);
    $form_friendly_name        = htmlspecialchars($row['friendly_name'],              ENT_QUOTES);
    $form_type                 = htmlspecialchars($row['type'],                 ENT_QUOTES);
    $form_destination          = htmlspecialchars($row['destination'],          ENT_QUOTES);
    $form_client               = htmlspecialchars($row['client'],               ENT_QUOTES);
    $form_dataset              = htmlspecialchars($row['dataset'],              ENT_QUOTES);
    $form_fstype               = htmlspecialchars($row['fstype'],               ENT_QUOTES);
    $form_storage              = htmlspecialchars($row['storage'],              ENT_QUOTES);
    $form_active               = htmlspecialchars($row['active'],               ENT_QUOTES);
    $form_backup_interval      = htmlspecialchars($row['backup_interval'],      ENT_QUOTES);
    $form_snapshot_retention   = htmlspecialchars($row['snapshot_retention'],   ENT_QUOTES);
    $form_replicator           = htmlspecialchars($row['replicator'],           ENT_QUOTES);
    $form_verify               = htmlspecialchars($row['verify'],               ENT_QUOTES);
    $form_verify_template      = htmlspecialchars($row['verify_template'],      ENT_QUOTES);
    $form_backup_verify_config = htmlspecialchars($row['backup_verify_config'], ENT_QUOTES);
  }

  $DATASET = explode(":", $row['dataset']);
  $CLIENT_TYPE = $DATASET[0];
  $CLIENT_NAME = $DATASET[1];
  $CLIENT_DATASET = $DATASET[2];

  $start_backup = "<a href='".$URL.$BASEURI."client/$row[id]/backupstart'><input type='button' value='Start Backup'/></a>";
  $schedule_backup = "<a href='".$URL.$BASEURI."client/$row[id]/backupschedule'><input type='button' value='Schedule Backup'/></a>";
  $start_verification = "<a href='".$URL.$BASEURI."client/$row[id]/verify'><input type='button' value='Start Verify'/></a>";

  echo "<form method='post'>";
  echo "<table style='border: 1px solid black'><tr><td></td><td></td><td></td><td></td><td width=300></td></tr>";
  echo "<tr><td width='300' align='right'>Physical Hostname:</td><td><font color=red>*</font></td><td width='400'><input type='text' name='hostname' value='$form_hostname' size='60'></td><td><font color='red'>$form_errors[form_hostname]</font></td><td>$start_backup$schedule_backup$start_verification</td></tr>";
  
  echo "<tr><td width='200' align='right'>Friendly Name:</td><td><font color=red>*</font></td><td width='400'><input type='text' name='friendly_name' value='$form_friendly_name' size='60'></td><td><font color='red'>$form_errors[form_friendly_name]</font></td></tr>";

  if ($form_active == '1'){
    $selected_client_active_yes = 'selected';
  }
  if ($form_active == '0'){
    $selected_client_active_no = 'selected';
  }
  echo "<tr><td width='200' align='right'>Active:</td><td><font color=red>*</font></td><td width='400'><select name='active' style='width: 370px;'>";
  echo "<option value=''>--- Select ---</option>";
  echo "<option value='1' $selected_client_active_yes>Yes</option>";
  echo "<option value='0' $selected_client_active_no>No</option>";
  echo "</td><td><font color='red'>$form_errors[form_active]</font></td></tr>";
 
  if ($CLIENT_TYPE == 'mysql'){
    $selected_client_type_mysql = 'selected';
  }
  if ($CLIENT_TYPE == 'clickhouse'){
    $selected_client_type_clickhouse = 'selected';
  }
  if ($CLIENT_TYPE == 'os'){
    $selected_client_type_os = 'selected';
  }
  if ($CLIENT_TYPE == 'data'){
    $selected_client_type_data = 'selected';
  }
  if ($CLIENT_TYPE == 'lxc_configs'){
    $selected_form_type_lxc_configs = 'selected';
  }
  if ($CLIENT_TYPE == 'vm_configs'){
    $selected_form_type_vm_configs = 'selected';
  }
  echo "<tr><td width='200' align='right'>Type:</td><td><font color=red>*</font></td><td width='400'><select name='type' style='width: 370px;'>";
  echo "<option value=''>--- Select ---</option>";
  echo "<option value='mysql' $selected_client_type_mysql>MySQL</option>";
  echo "<option value='clickhouse' $selected_client_type_clickhouse>Clickhouse</option>";
  echo "<option value='os' $selected_client_type_os>Operating System</option>";
  echo "<option value='data' $selected_client_type_data>Data</option>";
  echo "<option value='lxc_configs' $selected_form_type_lxc_configs>LXC Configs directory</option>";
  echo "<option value='vm_configs' $selected_form_type_vm_configs>VM Configs directory</option>";
  echo "</td><td><font color='red'>$form_errors[form_type]</font></td></tr>";

if ($form_destination == 'dataset'){
  $selected_form_destination_dataset = 'selected';
}
if ($form_destination == 'zvol'){
  $selected_form_destination_zvol = 'selected';
}
echo "<tr><td width='200' align='right'>Destination:</td><td><font color=red>*</font></td><td width='400'><select name='destination' style='width: 370px;'>";
echo "<option value=''>--- Select ---</option>";
echo "<option value='dataset' $selected_form_destination_dataset>Dataset</option>";
echo "<option value='zvol' $selected_form_destination_zvol>Zvol</option>";
echo "</td><td><font color='red'>$form_errors[form_type]</font></td></tr>";
  
  echo "<tr><td width='200' align='right'>Client hostname:</td><td><font color=red>*</font></td><td width='400'><input type='text' name='client' value='$CLIENT_NAME' size='60'></td><td><font color='red'>$form_errors[form_client]</font></td></tr>";
  
  echo "<tr><td width='200' align='right'>Dataset:</td><td><font color=red>*</font></td><td width='400'><input type='text' name='dataset' value='$CLIENT_DATASET' size='60'></td><td><font color='red'>$form_errors[form_dataset]</font></td></tr>";
  
  if ($form_fstype == 'zfs'){
    $selected_client_fstype_zfs = 'selected';
  }
  if ($form_fstype == 'ext4'){
    $selected_client_fstype_ext4 = 'selected';
  }
  echo "<tr><td width='200' align='right'>Filesystem Type:</td><td><font color=red>*</font></td><td width='400'><select name='fstype' style='width: 370px;'>";
  echo "<option value=''>--- Select ---</option>";
  echo "<option value='zfs' $selected_client_fstype_zfs>ZFS</option>";
  echo "<option value='ext4' $selected_client_fstype_ext4>Ext4</option>";
  echo "</td><td><font color='red'>$form_errors[form_fstype]</font></td></tr>";
  
  echo "<tr><td width='200' align='right'>Storage Node:</td><td><font color=red>*</font></td><td width='400'><select name='storage' style='width: 370px;'>";
  echo "<option value=''>--- Select ---</option>";
  $STORAGE_NODES = $mysqlconn->query("SELECT hostname FROM storage_nodes");
  for($i = 1; $row_storage = $STORAGE_NODES->fetch_assoc(); $i++) {
    if ($form_storage == $row_storage['hostname']){
      echo "<option value='$row_storage[hostname]' selected>$row_storage[hostname]</option>";
    } else {
      echo "<option value='$row_storage[hostname]'>$row_storage[hostname]</option>";
    }
  }
  echo "</td><td><font color='red'>$form_errors[form_storage]</font></td></tr>";
  
  echo "<tr><td width='200' align='right'>Backup Interval (Minutes):</td><td><font color=red>*</font></td><td width='400'><input type='text' name='backup_interval' value='$form_backup_interval' size='60'></td><td><font color='red'>$form_errors[form_backup_interval]</font></td></tr>";
  
  echo "<tr><td width='200' align='right'>Snapshot Retention (Days):</td><td><font color=red>*</font></td><td width='400'><input type='text' name='snapshot_retention' value='$form_snapshot_retention' size='60'></td><td><font color='red'>$form_errors[form_snapshot_retention]</font></td></tr>";
  
  echo "<tr><td width='200' align='right'>Geo Replicator:</td><td></td><td width='400'><select name='replicator' style='width: 370px;'>";
  echo "<option value=''>--- Select ---</option>";
  $STORAGE_NODES = $mysqlconn->query("SELECT hostname FROM storage_nodes");
  for($i = 1; $row_storage = $STORAGE_NODES->fetch_assoc(); $i++) {
    if ($form_replicator == $row_storage['hostname']){
      echo "<option value='$row_storage[hostname]' selected>$row_storage[hostname]</option>";
    } else {
      echo "<option value='$row_storage[hostname]'>$row_storage[hostname]</option>";
    }
  }
  echo "</td></tr>";
  
  if ($form_verify == '1'){
    $selected_client_verify_enabled = 'selected';
  }
  if ($form_verify == '0'){
    $selected_client_verify_disabled = 'selected';
  }
  echo "<tr><td width='200' align='right'>Perform Verifications:</td><td><font color=red>*</font></td><td width='400'><select name='verify' style='width: 370px;'>";
  echo "<option value=''>--- Select ---</option>";
  echo "<option value='1' $selected_client_verify_enabled>Enabled</option>";
  echo "<option value='0' $selected_client_verify_disabled>Disabled</option>";
  echo "</td><td></td></tr>";
  
  echo "<tr><td width='200' align='right'>Backup Verify Template:</td><td></td><td width='400'><select name='verify_template' style='width: 370px;'>";
  echo "<option value=''>--- Select ---</option>";
  $VERIFY_TEMPLATES = $mysqlconn->query("SELECT DISTINCT template FROM verify_queries ");
  for($i = 1; $row_verify_templates = $VERIFY_TEMPLATES->fetch_assoc(); $i++) {
    if ($form_verify_template == $row_verify_templates['template']){
      echo "<option value='$row_verify_templates[template]' selected>$row_verify_templates[template]</option>";
    } else {
      echo "<option value='$row_verify_templates[template]'>$row_verify_templates[template]</option>";
    }
  }
  echo "</td></tr>";
  
  echo "<tr><td width='200' align='right'>Backup Verify Config:</td><td></td><td width='400'><select name='backup_verify_config' style='width: 370px;'>";
  echo "<option value=''>--- Select ---</option>";
  $VERIFY_CONFIGS = $mysqlconn->query("SELECT name FROM backup_verify_configs");
  for($i = 1; $row_verify_config = $VERIFY_CONFIGS->fetch_assoc(); $i++) {
    if ($form_backup_verify_config == $row_verify_config['name']){
      echo "<option value='$row_verify_config[name]' selected>$row_verify_config[name]</option>";
    } else {
      echo "<option value='$row_verify_config[name]'>$row_verify_config[name]</option>";
    }
  }
  echo "</td></tr>";
 
  echo "<input type='hidden' name='client_id' value='$row[id]' />"; 
  
  echo "<tr><td width='200' align='right'></td><td></td><td width='400'><input type='submit' value='Modify Client' style='width: 200px; height: 50px;'></td></tr>";
  echo "</table>";
  echo "</form>";
}
?>
