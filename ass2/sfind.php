#!/srvr/cs3311psql/lib/php525/bin/php
<?
require("db.php");

if ($argc < 2 || !is_numeric($argv[1]) ) exit("Usage: ts SID\n");

$sid = $argv[1];

$db = dbConnect("dbname=a2");


$qry = <<<_SQL_
select p.id
from   People p join Students s on p.id=s.id
where  p.unswid = %d
_SQL_;
$id = dbOneValue($db,mkSQL($qry,$sid));
if (empty($id)) exit("Invalid SID: $sid\n");

$qry = <<<_SQL_
select transcript(%d)
_SQL_;


$info = dbQuery($db,mkSQL($qry,$sid));
if (!dbNresults($info)) exit("Invalid SID: $sid\n");
while($tuple = dbNext($info)){
	//print_r($tuple[0]);
	$b = str_replace(array(')','('), '', $tuple[0]);
	$a = split(",", $b);
	//var_dump($tuple[0]);
	if(!$a[0]) break;
	foreach ($a as $key => $value) {
		print("$value ");
	}
	echo "\n";
	
}
?>