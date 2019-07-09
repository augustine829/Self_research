<?php

$from = $to = "";
$debug = false;

// from and to are required, debug is optional
if (isset($_GET['from'])) {
  $from = $_GET['from'];
}
if (isset($_GET['to'])) {
  $to = $_GET['to'];
}
if (isset($_GET['debug'])) {
  $debug = $_GET['debug'];
}

$dir = dirname(__FILE__);
$debug_file = "/tmp/skip-sanity-check_debug_svn-log.xml";

// Verify input parameters
$date_re = '/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/';
if (!preg_match($date_re, $from) || !preg_match($date_re, $to)) {
    echo "Invalid date format";
    exit(1);
}

// Comand to fetch and parse svn log
$url = "http://svn.arrisi.com/dev";
$svn = "svn --username dailybuild --password dailybuild --non-interactive ";
$svn .= "log --xml -r '{" . $from . "}:{" . $to . "}' $url";
$parse = "xsltproc $dir/skip-sanity-check_svn-log_parser.xslt -";

if ($debug) {
  if (file_exists($debug_file)) {
    $svn = "cat $debug_file";
  }
  else {
    $svn .= " | tee $debug_file";
  }
}

// Run command
$data = shell_exec($svn . " | " . $parse);

// Count commits / author and add summary to the end
$author_re = '/\(author: ([^)]+)\)/';
$authors = array();
if (preg_match_all($author_re, $data, $authors)) {
  $author_count = array();
  foreach (array_count_values($authors[1]) as $author => $count) {
    $author_count[] = "$author: $count";
  }
  $summary = "<p>Author summary: " . join("; ", $author_count) . "</p>";
  $data = preg_replace('/(<\/body>)/', $summary . '$1', $data);
}

// Present result
echo $data;

?>
