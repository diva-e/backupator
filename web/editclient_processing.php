<?php

if (count($_POST) > '0'){
  $form_errors               = array();
  $form_client_id            = htmlspecialchars($_POST['client_id'],            ENT_QUOTES);
  $form_hostname             = htmlspecialchars($_POST['hostname'],             ENT_QUOTES);
  $form_friendly_name        = htmlspecialchars($_POST['friendly_name'],        ENT_QUOTES);
  $form_type                 = htmlspecialchars($_POST['type'],                 ENT_QUOTES);
  $form_destination          = htmlspecialchars($_POST['destination'],          ENT_QUOTES);
  $form_client               = htmlspecialchars($_POST['client'],               ENT_QUOTES);
  $form_dataset              = htmlspecialchars($_POST['dataset'],              ENT_QUOTES);
  $form_fstype               = htmlspecialchars($_POST['fstype'],               ENT_QUOTES);
  $form_storage              = htmlspecialchars($_POST['storage'],              ENT_QUOTES);
  $form_active               = htmlspecialchars($_POST['active'],               ENT_QUOTES);
  $form_backup_interval      = htmlspecialchars($_POST['backup_interval'],      ENT_QUOTES);
  $form_snapshot_retention   = htmlspecialchars($_POST['snapshot_retention'],   ENT_QUOTES);
  $form_replicator           = htmlspecialchars($_POST['replicator'],           ENT_QUOTES);
  $form_verify               = htmlspecialchars($_POST['verify'],               ENT_QUOTES);
  $form_verify_template      = htmlspecialchars($_POST['verify_template'],      ENT_QUOTES);
  $form_backup_verify_config = htmlspecialchars($_POST['backup_verify_config'], ENT_QUOTES);

  if (empty($form_hostname)){
    $form_errors['form_hostname']           = "Field is mandatory!";
  }

  if (empty($form_friendly_name)){
    $form_errors['form_friendly_name']      = "Field is mandatory!";
  }

  if (empty($form_type)){
    $form_errors['form_type']               = "Field is mandatory!";
  }

  if (empty($form_destination)){
    $form_errors['form_destination']        = "Field is mandatory!";
  }

  if (empty($form_client)){
    $form_errors['form_client']             = "Field is mandatory!";
  }

  if (empty($form_dataset)){
    $form_errors['form_dataset']            = "Field is mandatory!";
  }

  if (empty($form_fstype)){
    $form_errors['form_fstype']             = "Field is mandatory!";
  }

  if (empty($form_storage)){
    $form_errors['form_storage']            = "Field is mandatory!";
  }

  if (empty($form_backup_interval)){
    $form_errors['form_backup_interval']    = "Field is mandatory!";
  } else {
    if (!is_numeric($form_backup_interval)){
      $form_errors['form_backup_interval']    = "Value should be numeric!";
    }
  }

  if (empty($form_snapshot_retention)){
    $form_errors['form_snapshot_retention'] = "Field is mandatory!";
  } else {
    if (!is_numeric($form_snapshot_retention)){
      $form_errors['form_snapshot_retention']    = "Value should be numeric!";
    }
  }

  if (count($form_errors) == 0){
    $mysqlconn->query("UPDATE clients
    SET
    hostname='$form_hostname',
    friendly_name='$form_friendly_name',
    dataset='$form_type:$form_client:$form_dataset',
    fstype='$form_fstype',
    destination='$form_destination',
    backup_interval='$form_backup_interval',
    storage='$form_storage',
    replicator='$form_replicator',
    active='$form_active',
    verify='$form_verify',
    verify_template='$form_verify_template',
    backup_verify_config='$form_backup_verify_config',
    snapshot_retention='$form_snapshot_retention'
    WHERE
    id='$form_client_id';
    ");
    $mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Updated client: $form_type:$form_client:$form_dataset', SYSDATE())");
  }

}

?>
