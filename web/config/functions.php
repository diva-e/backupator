<?php

function calculate_time_span($date1, $date2){
    $seconds  = strtotime($date1) - strtotime($date2);

        $days = floor($seconds / 86400);
       $hours = floor(($seconds - ($days*86400)) / 3600);
        $mins = floor(($seconds - ($days*86400) - ($hours*3600)) / 60);
        $secs = floor(($seconds - ($days*86400) - ($hours*3600) - ($mins*60)));


        if($seconds < 60){
            if (strlen($secs) == 1){$secs = "0$secs";}
            $time = "00:00:".$secs;
        }else if($seconds < 60*60 ){
            $secs = $seconds-$mins*60;
            if (strlen($secs) == 1){$secs = "0$secs";}
            if (strlen($mins) == 1){$mins = "0$mins";}
            $time = "00:$mins:$secs";
        }else if($seconds < 24*60*60){
            if (strlen($secs) == 1){$secs = "0$secs";}
            if (strlen($mins) == 1){$mins = "0$mins";}
            if (strlen($hours) == 1){$hours = "0$hours";}
            $time = "$hours:$mins:$secs";
        }else{
            if (strlen($secs) == 1){$secs = "0$secs";}
            if (strlen($mins) == 1){$mins = "0$mins";}
            if (strlen($hours) == 1){$hours = "0$hours";}
            $time = "$days days $hours:$mins:$secs";
        }
        return array($time, $seconds);
}

function seconds_to_human_time($seconds){

        $days = floor($seconds / 86400);
       $hours = floor(($seconds - ($days*86400)) / 3600);
        $mins = floor(($seconds - ($days*86400) - ($hours*3600)) / 60);
        $secs = floor(($seconds - ($days*86400) - ($hours*3600) - ($mins*60)));


        if($seconds < 60){
            if (strlen($secs) == 1){$secs = "0$secs";}
            $time = "00:00:".$secs;
        }else if($seconds < 60*60 ){
            $secs = $seconds-$mins*60;
            if (strlen($secs) == 1){$secs = "0$secs";}
            if (strlen($mins) == 1){$mins = "0$mins";}
            $time = "00:$mins:$secs";
        }else if($seconds < 24*60*60){
            if (strlen($secs) == 1){$secs = "0$secs";}
            if (strlen($mins) == 1){$mins = "0$mins";}
            if (strlen($hours) == 1){$hours = "0$hours";}
            $time = "$hours:$mins:$secs";
        }else{
            if (strlen($secs) == 1){$secs = "0$secs";}
            if (strlen($mins) == 1){$mins = "0$mins";}
            if (strlen($hours) == 1){$hours = "0$hours";}
            $time = "$days days $hours:$mins:$secs";
        }
        return array($time, $seconds);
}

function human_size($value, $units){
    foreach (array('B', 'KB', 'MB', 'GB', 'TB') as $unit){
        if ($units == $unit){
            $UNIT=$unit;
            break;
        }
        if ($value > 1024 ){
            $value=$value/1024;
        }else{
            $UNIT=$unit;
            break;
        }
    }
    $new_value=number_format((float)$value, 2, '.', '');
    return $new_value." ".$UNIT;
}

?>
