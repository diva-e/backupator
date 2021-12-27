<?php

if (isset($_POST['hostname'])){
  $form_errors               = array();
  $form_hostname             = htmlspecialchars($_POST['hostname'],             ENT_QUOTES);
  $form_pool                 = htmlspecialchars($_POST['pool'],                 ENT_QUOTES);
  $form_storage_path         = htmlspecialchars($_POST['storage_path'],         ENT_QUOTES);
  $form_ip                   = htmlspecialchars($_POST['ip'],                   ENT_QUOTES);

  if (empty($form_hostname)){
    $form_errors['form_hostname']           = "Field is mandatory!";
  }

  if (empty($form_ip)){
    $form_errors['form_ip']                 = "Field is mandatory!";
  }

  if (empty($form_pool)){
    $form_errors['form_pool']               = "Field is mandatory!";
  }

  if (empty($form_storage_path)){
    $form_errors['form_storage_path']       = "Field is mandatory!";
  }

  if (count($form_errors) == 0){
    $mysqlconn->query("INSERT INTO storage_nodes
    (hostname, ip, pool, storage_path, active, replication_enabled, used_space, free_space)
    VALUES
    ('$form_hostname', '$form_ip', '$form_pool', '$form_storage_path', 0, 0, 0, 0);
    ");
    $mysqlconn->query("INSERT INTO uilog (username, action, time) VALUES ('$_SERVER[AUTHENTICATE_SAMACCOUNTNAME]', 'Added client: $form_type:$form_client:$form_dataset', SYSDATE())");
    echo "<meta http-equiv='refresh' content='0; url=".$URL.$BASEURI."storage'>";
  }

}

?>
