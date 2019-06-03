<?php

  $connect = mysql_connect("localhost", "root", "dcs5583") or die("Unable to connect database".mysql_error());

  mysql_select_db("test", $connect) or die ("sorry db connection fail");
?>
