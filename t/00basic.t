use v6;
use Test;
use LibGnuPDF :types, :subs;
use NativeCall;

my pdf_hash_t $hash;

is pdf_stm_supported_filter_p(PDF_STM_FILTER_AHEX_ENC), 1, 'AHEX_ENC is supported';
is pdf_stm_supported_filter_p(PDF_STM_FILTER_AHEX_DEC), 1, 'AHEX_DEC is supported';
is pdf_stm_supported_filter_p(PDF_STM_FILTER_PRED_ENC), 1, 'PRED_ENC is supported';
is pdf_stm_supported_filter_p(PDF_STM_FILTER_DCT_ENC), 0, 'DCT_ENC is not supported';
is pdf_stm_supported_filter_p(PDF_STM_FILTER_DCT_DEC), 1, 'DCT_DEC is supported';

my CArray[pdf_uchar_t] $buffer .= new("hello world!".encode("latin-1"));
my $enc-stm = pdf-check(&pdf_stm_mem_new, $buffer, $buffer.elems, 0, PDF_STM_READ);

is +pdf_stm_get_mode($enc-stm), +PDF_STM_READ, 'stream mode';

ok pdf-check(&pdf_stm_install_filter, $enc-stm, PDF_STM_FILTER_AHEX_ENC, $hash), 'install enc filter';

my CArray[pdf_uchar_t] $buf-enc .= new;
$buf-enc[100] = 0;

my CArray[pdf_size_t] $bytes .= new;
$bytes[0] = 0;
pdf-check(&pdf_stm_read, $enc-stm, $buf-enc, $buf-enc.elems-1, $bytes);
is $bytes[0], 25, "encoded length";
my Str $encoded = buf8.new( $buf-enc.head($bytes[0]) ).decode("latin-1");
is $encoded, "68656C6C6F20776F726C6421>", "encoded";

my $dec-stm = pdf-check(&pdf_stm_mem_new, $buf-enc, $bytes[0], 0, PDF_STM_READ);

ok pdf-check(&pdf_stm_install_filter, $dec-stm, PDF_STM_FILTER_AHEX_DEC, $hash), 'install dec filter';

my CArray[pdf_uchar_t] $buf-dec .= new;
$buf-dec[100] = 0;
pdf-check(&pdf_stm_read, $dec-stm, $buf-dec, $buf-dec.elems-1, $bytes);
my Str $decoded = buf8.new( $buf-dec.head($bytes[0]) ).decode("latin-1");
is $decoded, "hello world!", 'decoded';

.destroy
    for $dec-stm, $enc-stm;
done-testing;


