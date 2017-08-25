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

open($fh, "<:encoding(UTF-8)", $filename)
	or die $err_fopen . "'$filename' $!";
while (my $row = <$fh>) {
	chomp($row);
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
		$email_str .= $from . " wrote on " . $sent . ":\n";
		$was_subject = 1;
		next;
	}
	if ($was_subject == 1) {
		$was_subject = 0;
		next;
	}
	if (substr($row, 0, 1) ne ">") {
		my $last_space_idx = -1;
		my $idx = 0;
		while (1) {
			if ($idx > length($row) - 1) {
				$email_str .= "> " . $row . "\n";
				last;
			}
			if (substr($row, $idx, 1) eq " ") {
				$last_space_idx = $idx;
			}
			if ($idx > $row_limit) {
				if ($last_space_idx == -1) {
					$idx++;
					next;
				}
				$email_str .= "> " . substr($row, 0, $last_space_idx) . "\n";
				$row = substr($row, $last_space_idx + 1);
				$last_space_idx = -1;
				$idx = 0;
				next;
			}
			$idx++;
		}
	} else {
		$email_str .= ">" . $row . "\n";
	}
}
close $fh;

truncate $filename, 0;
open($fh, ">:encoding(UTF-8)", $filename)
	or die $err_fopen . "'$filename' $!";
print $fh $email_str;
close $fh;
