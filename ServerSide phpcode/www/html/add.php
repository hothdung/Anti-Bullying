<?php

define ('DB_NAME', 'stop_bullying');
define ('DB_USER', 'root');
define ('DB_PASSWORD', 'dcs5583');
define ('DB_HOST', 'localhost');

$link = mysql_connect(DB_HOST, DB_USER, DB_PASSWORD);

if(!$link){
	die('Could not connect: '.mysql_error());
}
$db_selected = mysql_select_db(DB_NAME, $link);
if(!db_selected){
	die('Can\'t use ' .DB_NAME . ': ' .mysql_error());
}

$value1 = $_POST[input1];
$value2 = $_POST[input2];
$sql = "INSERT INTO stop_bullying_second(sigid , sigr, time, minsig. maxsig) VALUES ('$sigid', '$sigr', '$time', '$minsig', '$maxsig')";

if (!mysql_query($sql)){
	die('Error: ' . mysql_error());
}

mysql_close();
?>
