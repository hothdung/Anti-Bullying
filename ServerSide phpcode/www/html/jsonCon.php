<?php 
//connect and select the database 
$connect = mysql_connect("localhost","root","dcs5583") or die('Database Not Connected. Please Fix the Issue! ' . mysql_error()); mysql_select_db("test", $connect); 

// get the contents of the JSON file 
$jsonCont = file_get_contents('studJson.json'); 

//decode JSON data to PHP array 
$content = json_decode($jsonCont, true); 

//Fetch the details of Student 
$std_id = $content['id']; 
$std_name = $content['name'];
$std_heart = $content['heart'];

//Insert the fetched Data into Database 
$query = "INSERT INTO student(std_id, std_name, std_heart) VALUES('$std_id', '$std_name', '$std_heart')"; 
if(!mysql_query($query,$connect)) 
{ die('Error : Query Not Executed. Please Fix the Issue! ' . mysql_error()); 
} 
else{ echo "Data Inserted Successully!!!"; 
} 
?>
