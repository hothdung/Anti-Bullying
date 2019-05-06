<?php
if(isset($_FILES['uploaded_file'])) {   

if($_FILES['uploaded_file']['error'] == 0) {
    // Connect to the database
    $dbLink = new mysqli('localhost', 'root', 'dcs5583', 'test');
    if(mysqli_connect_errno()) {
        die("MySQL connection failed: ". mysqli_connect_error());
    }

    // Gather all required data
    $id = $dbLink->real_escape_string($_FILES['uploaded_file']['id']);
    $name = $dbLink->real_escape_string($_FILES['uploaded_file']['name']);
    $location = $dbLink->real_escape_string($_FILES['uploaded_file']['location']);
    $size = intval($_FILES['uploaded_file']['size']);
    $date = $dbLink->real_escape_string(file_get_contents($_FILES  ['uploaded_file']['tmp_date']));

    // Create the SQL query
    $query = "INSERT INTO sound ('id', 'name', 'location', 'size', 'data', 'date')
        VALUES ('{$id}', '{$name}', '{$location}', {$size}, '{$data}', NOW())";

    // Execute the query
    $result = $dbLink->query($query);

    // Check if it was successfull
    if($result) {
        echo 'Success! Your file was successfully added!';
    }
    else {
        echo 'Error! Failed to insert the file'
           . "<pre>{$dbLink->error}</pre>";
    }
}
else {
    echo 'An error accured while the file was being uploaded. '
       . 'Error code: '. intval($_FILES['uploaded_file']['error']);
}

// Close the mysql connection
$dbLink->close();
 }
 else {
echo 'Error! A file was not sent!';
 }

 // Echo a link back to the main page
  echo '<p>Click <a href="form.html">here</a> to go back</p>';
 ?>
