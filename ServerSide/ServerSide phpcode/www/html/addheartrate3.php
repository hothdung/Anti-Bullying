<?php

$hostname = "localhost";
$username = "root";
$password = "dcs5583";
$db = "stop_bullying";

$dbconnect=mysqli_connect($hostname,$username,$password,$db);

if ($dbconnect->connect_error) {
  die("Database connection failed: " . $dbconnect->connect_error);
}


  $id=$_POST['id'];
  $jsonCont=$_POST['jsonData'];
  $content=json_decode($jsonCont, true);

  $std_bpm=$content['bpm'];
  $date=$_POST['date'];

  $query = "INSERT INTO heartrate (heartrate, date)
     VALUES ('$std_bpm', now())";

  if (!mysqli_query($dbconnect, $query)) {
        die('An error occurred when submitting your review.');
    } else {
      echo "Thanks for your review.";
    }


?>
