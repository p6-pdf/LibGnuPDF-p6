use v6;
use Test;
use LibGnuPDF;
use NativeCall;

my pdf_hash_t $hash;
my pdf_error_t $pdf_stat;

lives-ok {$hash = LibGnuPDF::pdf_hash_new($pdf_stat)}, 'pdf_hash_new - lives';
isa-ok $hash, pdf_hash_t;

my pdf_status_t $status = LibGnuPDF::pdf_error_get_status($pdf_stat);
is-deeply $status, 0, "normal status";

my pdf_domain_t $domain = LibGnuPDF::pdf_error_get_domain($pdf_stat);
is-deeply $domain, 0, "normal domain";

my $message = LibGnuPDF::pdf_error_get_message($pdf_stat);
is-deeply $message.deref[0], 0, "no error message";

done-testing;


