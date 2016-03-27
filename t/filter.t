use v6;
use NativeCall;
use LibGnuPDF :subs, :types;
use LibGnuPDF::Filter;
use LibGnuPDF::Object;
use Test;

is-deeply LibGnuPDF::Filter.filter-spec('ASCIIHexDecode'), { :can-enc, :can-dec, :dec(PDF_STM_FILTER_AHEX_DEC), :enc(PDF_STM_FILTER_AHEX_ENC) }, 'ASCIIHexDecode spec';
is-deeply LibGnuPDF::Filter.filter-spec('AHx'), LibGnuPDF::Filter.filter-spec('ASCIIHexDecode'), 'AHx spec';
is LibGnuPDF::Filter.filter-spec('FlateDecode'), { :can-enc, :can-dec, :dec(PDF_STM_FILTER_FLATE_DEC), :enc(PDF_STM_FILTER_FLATE_ENC), :predictors }, 'FlateHexDecode spec';
is LibGnuPDF::Filter.filter-spec('Crypt'), { :!can-enc, :!can-dec, }, 'Crypt spec (nyi)';

dies-ok { LibGnuPDF::Filter.filter-spec('Wtf') }, 'unknown filter - dies';

my CArray[pdf_uchar_t] $buffer .= new(("hello world!").encode("latin-1"));
my $enc-stm = pdf-check(&pdf_stm_mem_new, $buffer, $buffer.elems, 0, PDF_STM_READ);

my $decode-parms = LibGnuPDF::Object::to-pdf-hash( { :BitsPerComponent(4), :Predictor(14), :Colors(3), :Columns(4) } );

ok pdf-check(&pdf_stm_install_filter, $enc-stm, PDF_STM_FILTER_PRED_ENC, $decode-parms), 'install enc predictor';

my CArray[pdf_uchar_t] $buf-enc .= new;
$buf-enc[100] = 0;

my CArray[pdf_size_t] $bytes .= new;
$bytes[0] = 0;
pdf-check(&pdf_stm_read, $enc-stm, $buf-enc, $buf-enc.elems-1, $bytes);

my $dec-stm = pdf-check(&pdf_stm_mem_new, $buf-enc, $bytes[0], 0, PDF_STM_READ);

ok pdf-check(&pdf_stm_install_filter, $dec-stm, PDF_STM_FILTER_PRED_DEC, $decode-parms), 'install dec predictor';

my CArray[pdf_uchar_t] $buf-dec .= new;
$buf-dec[100] = 0;
pdf-check(&pdf_stm_read, $dec-stm, $buf-dec, $buf-dec.elems-1, $bytes);
my $decoded = buf8.new( $buf-dec.head($bytes[0]) ).decode("latin-1");
is $decoded, "hello world!", 'decoded';

my $input = '100 100 Td (Hello, world!) Tj';
my %dict = ( :Filter['ASCIIHexDecode',], );
my $encoded = LibGnuPDF::Filter.encode( $input, :%dict );
isnt $encoded.decode('latin-1'), $input, 'encoding sanity';

$decoded = LibGnuPDF::Filter.decode( $encoded, :%dict );
is $decoded.decode('latin-1'), $input, 'decoding sanity';

done-testing;
