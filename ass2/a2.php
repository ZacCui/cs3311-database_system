<?php
// COMP3311 18s1 Assignment 2
// Functions for assignment Tasks A-E
// Written by <<Ziyi Cui>> (<<z5097491>>), May 2018

// assumes that defs.php has already been included


// Task A: get members of an academic object group

// E.g. list($type,$codes) = membersOf($db, 111899)
// Inputs:
//  $db = open database handle
//  $groupID = acad_object_group.id value
// Outputs:
//  array(GroupType,array(Codes...))
//  GroupType = "subject"|"stream"|"program"
//  Codes = acad object codes in alphabetical order
//  e.g. array("subject",array("COMP2041","COMP2911"))

function membersOf($db,$groupID)
{
	$q = "select * from acad_object_groups where id = %d";
	$grp = dbOneTuple($db, mkSQL($q, $groupID));

	$q = "select member(%d)";
	$res = dbQuery($db, mkSQL($q, $groupID));
	$arr = array();
	while ($tuple = dbNext($res)) {
		array_push($arr, $tuple[0]); 

	}
	$arr = array_unique($arr);
	$arr = array_values($arr);
	sort($arr);

	return array($grp["gtype"], $arr); // stub
}


// Task B: check if given object is in a group

// E.g. if (inGroup($db, "COMP3311", 111938)) ...
// Inputs:
//  $db = open database handle
//  $code = code for acad object (program,stream,subject)
//  $groupID = acad_object_group.id value
// Outputs:
//  true/false

function inGroup($db, $code, $groupID)
{
	$arr = membersOf($db,$groupID);
	//print_r($arr[1]);
	foreach ($arr[1] as $key => $value) {
		if(preg_match('/^(FREE|all|ALL)/',$value)){
			if(!preg_match("/GEN/", $code)) return true;
		} 
		if(preg_match("/GEN/", $value)) $value = preg_replace('/(GEN).*/', '\1[^E]....', $value);
		$value = preg_replace('/#/', '.', $value);
		if(preg_match("/$value/", $code)) return true;

		
	}
	return false; // stub
}


// Task C: can a subject be used to satisfy a rule

// E.g. if (canSatisfy($db, "COMP3311", 2449, $enr)) ...
// Inputs:
//  $db = open database handle
//  $code = code for acad object (program,stream,subject)
//  $ruleID = rules.id value
//  $enr = array(ProgramID,array(StreamIDs...))
// Outputs:

function canSatisfy($db, $code, $ruleID, $enrolment)
{
	//print_r($enrolment);
	$q = "select ao_group
	from rules r 
	where r.id = %d";
	$grp = dbOneTuple($db, mkSQL($q, $ruleID));
	//print($grp[0]);
	if(!$grp[0]) return false;
	if(inGroup($db,$code,$grp[0])) return true;
	foreach ($enrolment[1] as $key => $value) {
		if(inGroup($db,$code,$grp[0])) return true;

	}
	return false; // stub
}


// Task D: determine student progress through a degree

// E.g. $vtrans = progress($db, 3012345, "05s1");
// Inputs:
//  $db = open database handle
//  $stuID = People.unswid value (i.e. unsw student id)
//  $semester = code for semester (e.g. "09s2")
// Outputs:
//  Virtual transcript array (see spec for details)

function progress($db, $stuID, $term)
{
	//print("$stuID,$term");

	$q = "select p.program, p.id 
	from Program_enrolments p
	where p.semester = %d
	and p.student = %d";
	//$pid = fasle;
	$pid = dbOneTuple($db,mkSQL($q,$term,$stuID));
	//print_r($pid);
	//var_dump($pid);
	if(!$pid ){
		$q = "select p.program, p.id
		from Program_enrolments p
		where p.student = %d
		order by semester desc";
		$pid = dbOneTuple($db,mkSQL($q,$stuID));
	}
	
	$q = "select id2code(%d,%s)";
	$code = dbOneTuple($db,mkSQL($q,$pid[0],'programs'));
	//print_r($code);

	$q = "select p.stream
	from Stream_enrolments p
	where p.partof = %d";
	$sid = dbQuery($db,mkSQL($q,$pid[1]));
	$sid_arr = array();
	while ($tup = dbNext($sid)){
		if($tup[0]) array_push($sid_arr,$tup[0]);
	}
	//print_r($sid_arr);

	$scode = array();

	foreach ($sid_arr as $key => $value) {
		$q = "select id2code(%d,%s)";
		$s_code = dbOneTuple($db,mkSQL($q,$value,'streams'));
		array_push($scode, $s_code[0]);
	}

	//print_r($scode);
	$q = "select id, type, ao_group, min
	from rules_for_prog 
	where code = %s
	order by type";
	$rules = dbQuery($db,mkSQL($q,$code[0]));

	$t = array();
	while ($tup = dbNext($rules)){
		if($tup[0]) array_push($t,$tup);
	}

	foreach ($scode as $key => $value) {
		$q = "select id, type, ao_group, min
		from rules_for_stream
		where code = %s
		order by type";
		$rules = dbQuery($db,mkSQL($q,$value));

		while ($tup = dbNext($rules)){
			if($tup[0]) array_push($t,$tup);
		}
	}

	$q = "select transcript(%d,%d)";
	$trans = dbQuery($db, mkSQL($q,$stuID,$term));

	$res = array();

	usort($t, "pri2");
	//print_r($t);
	$list = array('CC','PE','FE','GE','LR');
	foreach ($t as $key => $value){
		//print_r($value);
		$name = ruleName($db,$value['id']);
		//print("$name\n");
		$flag = in_array($value['type'], $list);
		if( $value['min'] && $flag){
			$res[$name] = array('complete' => 0,'todo' => $value['min']);
		}
	}
	//print_r($res);
	usort($t,"pri");
	//print_r($t);

	//print_r($t);

	$results = array();
	while ($tuple = dbNext($trans)) {
		//print_r("$tuple[0]\n");
		//var_dump($tuple[0]);
		$tuple[0] = preg_replace('/^\((.*)\)$/', '\1', $tuple[0]);
		$tuple[0] = preg_replace('/"/', '{', $tuple[0],1);
		$tuple[0] = preg_replace('/"/', '}', $tuple[0],1);
		//print("$tuple[0]\n");

		/*if(preg_match('/Overall WAM/', $tuple[0])){
			$arr = preg_split('/,/', $tuple[0]);
		}else{
			$tuple[0] = preg_replace('/(,)(,)/', '\1 \2', $tuple[0]);
			$tuple[0] = preg_replace('/([^a-z],)/', '\1@', $tuple[0]);
			//print("$tuple[0]\n");
			$arr = preg_split('/,@/', $tuple[0]);
		}*/
		$arr = preg_split('/\,(?![^{]*})/', $tuple[0]);

		//$arr = str_getcsv($s, ",");
		//print_r($arr);
		$arr[2] = preg_replace('/[\{\}]/', '', $arr[2]);
		if($arr[0]){
			foreach ($t as $key => $value) {
				if(canSatisfy($db, $arr[0], $value['id'], array($pid,$sid_arr))){
					$arr[6] = ruleName($db,$value['id']);
					if($arr[4] == 'FL') $arr[6] = "Failed. Does not count";
					if(!$arr[3] && $arr[4] != 'SY'){
						$arr[3] = null;
						$arr[5] = null;
						$arr[6] = "Incomplete. Does not yet count";
					}
					if($arr[4] == 'SY') $arr[3] = null;
					if(!$arr[6] && $arr[0])  $arr[6] = "Fits no requirement. Does not count";
					if(!preg_match('/not (yet )?count/', $arr[6])){
						$name = ruleName($db,$value['id']);
						if($res[$name]['todo'] == 0){
							$arr[6] = "Fits no requirement. Does not count";
						}else{
							$res[$name]['complete'] += $arr[5];
							$res[$name]['todo'] -= $arr[5];
						}
					}
					break;
				}
			}
		}

		if(!$arr[0]){
			$arr = array_filter($arr);
			$arr = array_values($arr);
		}
		//print_r($arr);
		if(preg_match('/No WAM available/',$arr[0])){
			$arr[0] = "Overall WAM";
			$arr[1] = null;
			$arr[2] = null;
		}
		array_push($results, $arr);

	}
	//print_r($results);
	foreach ($res as $key => $value){
		if($value['todo'] == 0) continue;
		$str = $value['complete'] . " UOC so far; need ". $value['todo'] . " UOC more";
		array_push($results, array($str, $key));
	}

	return $results; // stub
}


function pri($a, $b){
	$order = array('CC','PE','FE');
	$_a = array_search($a['type'], $order);
	$_b = array_search($b['type'], $order);
	if($_a === false && $_b === false) { 
        return asd($a,$b);                     
    }
    else if ($_a === false) {           
        return 1;                     
    }
    else if ($_b === false) {          
        return -1;                   
    }
    else {
        return $_a - $_b;
    }
}

function pri2($a, $b){
	$order = array('CC','PE','FE','GE','LR');
	$_a = array_search($a['type'], $order);
	$_b = array_search($b['type'], $order);
	if($_a === false && $_b === false) { 
        return 0;                     
    }
    else if ($_a === false) {           
        return 1;                     
    }
    else if ($_b === false) {          
        return -1;                   
    }
    else {
    	if($a['type'] === $b['type']){
    		return asd($a,$b);
    	}else{
        	return $_a - $_b;
        }
    }
}

function asd($a, $b){
	if($a['id'] > $b['id']){
		return 1;
	}else if ($a['id'] > $b['id']){
		return -1;
	}else{
		return 0;
	}
}

// Task E:

// E.g. $advice = advice($db, 3012345, 162, 164)
// Inputs:
//  $db = open database handle
//  $studentID = People.unswid value (i.e. unsw student id)
//  $currTermID = code for current semester (e.g. "09s2")
//  $nextTermID = code for next semester (e.g. "10s1")
// Outputs:
//  Advice array (see spec for details)

function advice($db, $studentID, $currTermID, $nextTermID)
{
	//print("$studentID, $currTermID, $nextTermID\n");
	$q = "select p.program, p.id 
	from Program_enrolments p
	where p.semester = %d
	and p.student = %d";
	//$pid = fasle;
	$pid = dbOneTuple($db,mkSQL($q,$currTermID,$studentID));
	//print_r($pid);
	//var_dump($pid);
	if(!$pid ){
		$q = "select p.program, p.id
		from Program_enrolments p
		where p.student = %d
		order by semester desc";
		$pid = dbOneTuple($db,mkSQL($q,$studentID));
	}
	
	$q = "select id2code(%d,%s)";
	$code = dbOneTuple($db,mkSQL($q,$pid[0],'programs'));
	//print_r($code);

	$q = "select p.stream
	from Stream_enrolments p
	where p.partof = %d";
	$sid = dbQuery($db,mkSQL($q,$pid[1]));
	$sid_arr = array();
	while ($tup = dbNext($sid)){
		if($tup[0]) array_push($sid_arr,$tup[0]);
	}
	//print_r($sid_arr);

	$scode = array();

	foreach ($sid_arr as $key => $value) {
		$q = "select id2code(%d,%s)";
		$s_code = dbOneTuple($db,mkSQL($q,$value,'streams'));
		array_push($scode, $s_code[0]);
	}

	$q = "select id, type, ao_group, min
	from rules_for_prog 
	where code = %s
	order by type";
	$rules = dbQuery($db,mkSQL($q,$code[0]));

	//$list = array('CC','PE','RQ','MR','WM');
	$t = array();
	while ($tup = dbNext($rules)){
		if($tup[0]) array_push($t,$tup);
	}

	foreach ($scode as $key => $value) {
		$q = "select id, type, ao_group, min
		from rules_for_stream
		where code = %s
		order by type";
		$rules = dbQuery($db,mkSQL($q,$value));

		while ($tup = dbNext($rules)){
			if($tup[0])  array_push($t,$tup);
		}
	}
	//print_r($t);
	//debug
	$MR = array();
	$WM = array();
	foreach ($t as $key => $value) {
		if($value['type'] == 'MR'){
			$text = showRule($db,$value['id']);
			$uoc_needed = preg_replace('/^.*at least (\d+) UOC.*$/', '\1', $text);
			$pattern = preg_replace('/^.*undertaking (.*)$/', '/\1/', $text);
			$pattern = preg_replace('/#/', '.', $pattern);
			$MR[$value['id']] = array('uoc' => $uoc_needed, 'pattern' => $pattern); 

		}
		if($value['type'] == 'WM'){
			$text = showRule($db,$value['id']);
			$min_wam = preg_replace('/^.*(\d+).*$/', '\1', $text);
			$WM[$value['ao_group']] = $min_wam; 
		}
		/*print($value['type']);
		print("\n");

		print(showRule($db,$value['id']));
		print("\n");*/
	}
	//
	//print_r($MR);

	$progress = progress($db, $studentID, $currTermID);
	//print_r($progress);
	$complete = array();
	$todo = array();
	$complete_flag = true;
	$uoc = 0;
	$wam = 0;
	$add = 0;
	$added_courses = array();
	foreach ($progress as $key => $value) {
		if($complete_flag){
			if(preg_match('/Overall WAM/', $value[0])){
				$complete_flag = false;
				//print_r($value);
				if($value[1]) $wam = $value[1];
				if($value[2]) $uoc = $value[2];
				
				continue;
			}
			if(!preg_match('/^[FD].*not (yet )?count/', $value[6])){
				array_push($complete, $value[0]);
				if(preg_match('/^Incomplete/', $value[6])){
					$q = "select uoc 
					from subjects 
					where code = %s";
					$c_uoc = dbOneTuple($db,mkSQL($q,$value[0]));
					//print_r($c_uoc);
					$add += $c_uoc['uoc'];
					array_push($added_courses, array($value[0],$c_uoc['uoc']));
				}
			}
		}else{
			array_push($todo, $value);
		}
	}
	usort($t, 'pri2');
	//print_r($t);
	//print_r($added_courses);
	$uoc += $add;
	$sub = array('GE' => 0, 'FE' => 0);
	foreach ($added_courses as $key => $course) {
		foreach ($t as $key => $value) {
				//print_r($course);
				//print_r($value);
				if(canSatisfy($db, $course[0], $value['id'], array($pid,$sid_arr))){
					$sub[$value['type']] += $course[1];
					break;
				}
		}
	}
	//print_r($sub);
	//print("$uoc, $wam\n");
	// use todo find the member of courses
	$temp = array();
	foreach ($todo as $key => $value) {
		//print_r($value);
		foreach ($t as $key => $rule) {
			//print_r($rule);
			if($value[1] == ruleName($db,$rule['id']) or $rule['type'] == 'RQ'){
				//print_r($rule['ao_group']);
				$value[2] = $rule['ao_group'];
				$value[0] = preg_replace('/^.* (\d+) UOC more/', '\1' , $value[0]);
				if(preg_match('/Free/', $value[1])){
					$value[0] -= $sub['FE'];
				}
				if(preg_match('/GE/', $value[1])){
					$value[0] -= $sub['GE'];
				}
				array_push($temp, $value);
				break;
			}

		}
	}

	$q = "select career 
	from programs 
	where id = %d";

	$my_career = dbOneTuple($db,mkSQL($q,$pid[0]));
	//print_r($my_career);

	$todo = $temp;
	//print_r($todo);
	//print_r($complete);
	//print_r($WM);
	$already_in = array();
	$res = array();
	foreach ($todo as $key => $value) {
		$members = membersOf($db,$value[2]);
		foreach ($members[1] as $key => $member) {
			//print("$member\n");
			if(in_array($member,$complete)) continue;

			$flag = false;
			$career_flag = false;

			$q = " select s.id,s.name,s.uoc
		    from subjects s
		    join courses c on (c.subject = s.id)
		    join (select transcript(%d,%d)) t on (s.code !~ cast(t as text))
		    where s.code = %s and c.semester = %d";
		    $course_info = dbOneTuple($db,mkSQL($q,$studentID,$currTermID,$member,$nextTermID));

		    if(!$course_info) continue;
		    if($course_info['uoc'] <= 3) continue;

			$q = "select career
			from subjects
			where code = %s";
			$c_career = dbOneTuple($db, mkSQL($q,$member));

			if($c_career[0] != $my_career[0]){
				$career_flag = true;
				$q = "select s.career,sp.career
				from subjects s
				join subject_prereqs sp on (s.id = sp.subject)
				where s.code = %s";
				$career = dbQuery($db,mkSQL($q,$member));
				while ($tup1 = dbNext($career)) {
					if(in_array($my_career[0], $tup1)){
						$career_flag = false;
						break;
					}
				}
			}

			if($career_flag) continue;

		    $q = "select ao.id as ao_group, ao.glogic
			from acad_object_groups ao
			where exists (
			  	select ao_group
			    from rules rs
			    join (select rule
			    from subject_prereqs
			    where subject = %d) r
			    on (r.rule = rs.id)
			    where ao_group = ao.id
			)";
		   	$pre = dbQuery($db,mkSQL($q,$course_info['id']));
		   	if($pre){
		   		$temp = array();
		   		$logic = null;
				while ($tup = dbNext($pre)) {
					//print_r($tup);
					if(!$tup['ao_group']) continue;
					//print("$member \n");
				  	$pre_courses = membersOf($db,$tup['ao_group']);
				  	//print_r($pre_courses[1]);
				  	//print_r($tup['glogic']);
				  	foreach ($pre_courses[1] as $k => $v) {
				  		array_push($temp, $v);

				  	}
				  	if($tup['glogic'] and !$logic) $logic = $tup['glogic'];
				}
				foreach ($temp as $key => $course) {
				  	if($logic === 'and'){
				  		//print("and\n");
				  		if(!is_in($temp,$complete)){
					   		$flag = true;
					  		//print("$member $flag\n");
					   		break;
				   		}
				  	}else{
					   	if(!is_in_or($temp,$complete)){
					   		//print("or\n");
					   		$flag = true;
					   		//print("$member $flag\n");
					   		break;
					   	}
					}
				}
			}
			//print("\n$member $flag \n");
			//print_r($temp);


			if($flag) continue;


			$q = "select excluded , equivalent 
			from subjects 
			where id = %s";
			$ex = dbOneTuple($db,mkSQL($q,$course_info['id']));
			//print($member);
			if($ex){
				if($ex[0] != null){
					$ex_courses = membersOf($db,$ex[0]);
					//print_r($ex_courses);
					if(is_in_or($ex_courses[1],$complete)) $flag = true;
				}
				if($ex[1] != null){
					$ex_courses = membersOf($db,$ex[1]);
					//print_r($ex_courses);
					if(is_in_or($ex_courses[1],$complete)) $flag = true;
				}
			}
			//print("\n$member $flag \n");


			if($flag) continue;



			foreach ($MR as $key => $mr_rule) {
				//print($key);
				//print_r($mr_rule);
				//print("\n$member");
				if(preg_match($mr_rule['pattern'],$member)){
					//print('\n!!!match!!!\n');
					/*print("$member $uoc < ");
					print($mr_rule['uoc']);
					print("\n");*/
					if($uoc < $mr_rule['uoc']){
						$flag = true;
						break;
					}
				}
			}
			//print("$member $flag\n");

			if($flag) continue;


			foreach ($WM as $key => $wm_rule) {
				if(inGroup($db,$member,$key)){
					print("$member $wam < $wm_rule?\n");
					if($wam < $wm_rule){
						$flag = true;
						break;
					}
				}
			}


		   	if($flag) continue;
		   	if(in_array($member, $already_in)) continue;

		   	array_push($already_in, $member);
		   	array_push($res, array($member,$course_info['name'],$course_info['uoc'],$value[1]));
		   	//$flag = false;
		}
	}
	//print($res);
	//array("GenEd...","General Education (many choices)",9,"Gen Ed"),
	//array("Free....","Free Electives (many choices)",18,"Free Electives"),

	foreach ($todo as $key => $value) {
		$flag = false;
		if(preg_match('/GE|Gen/', $value[1])){
			foreach ($MR as $key => $mr) {
				if(preg_match($mr['pattern'],"GENG####")){
					if($uoc < $mr['uoc']){
						$flag = true;
						break;
					}
				}
			}
			if($flag) continue;
			array_push($res, array("GenEd...","General Education (many choices)",$value[0],$value[1]));
		}
		if(preg_match('/Free/', $value[1])){
			array_push($res, array("Free....","Free Electives (many choices)",$value[0],$value[1]));
		}
	}
	//print_r($res);

	// shortlist the course
	//print_r($uoc);


	// sort courses
	return $res; // stub
}

function is_in($a,$b){
	foreach ($a as $key => $value) {
		if(!in_array($value, $b)) return false;
	}
	return true;
}

function is_in_or($a,$b){
	foreach ($a as $key => $value) {
		if(in_array($value, $b)) return true;
	}
	return false;
}

?>
