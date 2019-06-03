<?php

$connection = mysqli_connect("localhost", "root", "dcs5583","test") or die("Could not connect! <br>Error Returned By MySQL Server".mysqli_connect_error());
if($connection){
  echo "Connection is successful!";
    }
mysql_close($connection);

?>


