<?php
   $host = 'localhost';
    $user = 'root';
    $pw = 'root';
        $dbName = 'myClass';
        $mysqli = new mysqli($host, $user, $pw, $dbName);
         
    if($mysqli){
        echo "MySQL access sucessfuly";
    }else{
        echo "MySQL access failed";
    }
?>

