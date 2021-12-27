<?php

echo "<script>
function deactivate(client){
    window.location.href = '$URL' + '$BASEURI' + '$PAGE' + '/' + client + '/deactivate';
}

function activate(client){
    window.location.href = '$URL' + '$BASEURI' + '$PAGE' + '/' + client + '/activate';
}

function deactivate_replication(client){
    window.location.href = '$URL' + '$BASEURI' + '$PAGE' + '/' + client + '/deactivate_replication';
}

function activate_replication(client){
    window.location.href = '$URL' + '$BASEURI' + '$PAGE' + '/' + client + '/activate_replication';
}

function backupstart(client){
    window.location.href = '$URL' + '$BASEURI' + '$PAGE' + '/' + client + '/backupstart';
}

function confirm_backupstart(client){
    window.location.href = '$URL' + '$BASEURI' + '$PAGE' + '/' + client + '/backupstart/CONFIRM';
}

function verify(client){
    window.location.href = '$URL' + '$BASEURI' + '$PAGE' + '/' + client + '/verify';
}

function confirm_verify(client){
    window.location.href = '$URL' + '$BASEURI' + '$PAGE' + '/' + client + '/verify/CONFIRM';
}

function backupschedule(client){
    window.location.href = '$URL' + '$BASEURI' + '$PAGE' + '/' + client + '/backupschedule';
}
</script>
";

?>
