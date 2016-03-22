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

is LibGnuPDF::pdf_stm_supported_filter_p(PDF_STM_FILTER_AHEX_ENC), 1, 'AHEX_ENC is supported';
is LibGnuPDF::pdf_stm_supported_filter_p(PDF_STM_FILTER_AHEX_DEC), 1, 'AHEX_DEC is supported';
is LibGnuPDF::pdf_stm_supported_filter_p(PDF_STM_FILTER_PRED_ENC), 1, 'PRED_ENC is supported';
is LibGnuPDF::pdf_stm_supported_filter_p(PDF_STM_FILTER_DCT_ENC), 0, 'DCT_ENC is not supported';
is LibGnuPDF::pdf_stm_supported_filter_p(PDF_STM_FILTER_DCT_DEC), 1, 'DCT_DEC is supported';

done-testing;


