use strict;
use warnings;

my $fh;
my $filename = "email.txt";
my $text_line = "___________________";
my $text_from = "From: ";
my $text_to = "To: ";
my $text_cc = "Cc: ";
my $text_bcc = "Bcc: ";
my $text_sent = "Sent: ";
my $text_subject = "Subject: ";
my $err_fopen = "could not open ";
my $email_str = "";
my $from = "";
my $sent = "";
my $was_subject = 0;
my $in_header = 0;
my $first_row_with_text = 0;
my $first_line = 0;
my $row_limit = 76;
my $row_remainder = "";

open($fh, "<:encoding(UTF-8)", $filename)
	or die $err_fopen . "'$filename' $!";
while (my $row = <$fh>) {
	chomp($row);
	$row = $row_remainder . $row;
	if ($row_remainder ne "") {
		$row .= "\n>";
	}
	$row_remainder = "";
	if (length($row) > $row_limit && substr($row, 0, 1) ne ">") {
		my $last_space_idx = 0;
		for (my $i = 0; $i < length($row); $i++) {
			if (substr($row, $i, 1) eq " ") {
				$last_space_idx = $i;
			}
			if ($i > $row_limit && $last_space_idx > 0) {
				$row_remainder = substr($row, $last_space_idx + 1);
				$row = substr($row, 0, $last_space_idx);
			}
		}
	}
	my $idx = 0;
	if ($row ne "") {
		$first_row_with_text = 1;
	}
	if ($first_row_with_text == 0 || index($row, $text_to) == 0 ||
	    index($row, $text_cc) == 0 || index($row, $text_bcc) == 0) {
		next;
	}
	if (index($row, $text_line) == 0) {
		$in_header = 1;
		if ($first_line == 0) {
			$first_line = 1;
			next;
		}
		$email_str .= ">\n";
		next;
	}
	$idx = index($row, $text_from);
	if ($idx == 0 && $in_header == 1) {
		$from = substr($row, $idx + length($text_from));
		next;
	}
	$idx = index($row, $text_sent);
	if ($idx == 0 && $in_header == 1) {
		$sent = substr($row, $idx + length($text_sent));
		next;
	}
	$idx = index($row, $text_subject);
	if ($idx == 0 && $in_header == 1) {
		$in_header = 0;
		if ($email_str eq "\n") {
			$email_str = "";
		}
		$idx = index($row, ">");
		if ($idx == 0) {
			$email_str .= ">" . $row . "\n";
			next;
		}
		$email_str .= "On " . $sent . ", " . $from . " wrote:" . "\n";
		$was_subject = 1;
		next;
	}
	if ($was_subject == 1) {
		$was_subject = 0;
		next;
	}
	my $prefix = ">";
	if (substr($row, 0, 1) ne ">" && $row ne "") {
		$prefix .= " ";
	}
	$email_str .= $prefix . $row . "\n";
}
close $fh;

truncate $filename, 0;
open($fh, ">:encoding(UTF-8)", $filename)
	or die $err_fopen . "'$filename' $!";
print $fh $email_str;
close $fh;
