<?php

$hostname = "localhost";
$username = "root";
$password = "dcs5583";
$db = "stop_bullying";

$dbconnect=mysqli_connect($hostname,$username,$password,$db);

if ($dbconnect->connect_error) {
  die("Database connection failed: " . $dbconnect->connect_error);
}

if(isset($_POST['submit'])) {
  $id=$_POST['id'];
  $signals=$_POST['signals'];
  $date=$_POST['date'];

  $query = "INSERT INTO sound (signals, date)
     VALUES ('$signals', now())";

  if (!mysqli_query($dbconnect, $query)) {
        die('An error occurred when submitting your review.');
    } else {
      echo "Thanks for your review.";
    }

}
?>
