<?php
 $host = 'localhost';
 $user = 'root';
 $pw = 'dcs5583';
 $dbName = 'myService';

// $conn=mysqli_connect($host, $user, $pw, $dbName);
// if(mysqli_connect_error($conn)){
 //   echo "mysql access failed";
 //   exit
// }
// echo "mysql access successfuly"

   $mysqli = new mysqli($host, $user, $pw, $dbName);
 $User=$_POST['User'];
 $accelerometer=$_POST['accelerometer'];
 $sound=$_POST['sound'];
 $ECG=$_POST['ECG'];

 
 $sql = "insert into account_info";
 $sql = $sql. "values('$User','$accelerometer','$sound ','$ECG')";
 if($mysqli->query($sql)){
  echo 'success inserting';
 }else{
  echo 'fail to insert sql';
 }
?>
