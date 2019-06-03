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
  $x_axis=$_POST['x_axis'];
  $y_axis=$_POST['y_axis'];
  $date=$_POST['date'];

  $query = "INSERT INTO gps_data (x_axis, y_axis, date)
     VALUES ('$x_axis', '$y_axis', now())";

  if (!mysqli_query($dbconnect, $query)) {
        die('An error occurred when submitting your review.');
    } else {
      echo "Thanks for your review.";
    }

}
?>
