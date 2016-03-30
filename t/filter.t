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

my $flate-enc = buf8.new: [104, 222, 98, 98, 100, 16, 96, 96, 98, 96,
186, 10, 34, 20, 129, 4, 227, 2, 32, 193, 186, 22, 72, 48, 203, 131,
8, 37, 16, 33, 13, 34, 50, 65, 74, 30, 128, 88, 203, 64, 196, 82, 16,
119, 23, 144, 224, 206, 7, 18, 82, 7, 128, 4, 251, 121, 32, 97, 117,
6, 72, 84, 1, 13, 96, 100, 72, 5, 178, 24, 24, 24, 169, 78, 252, 103,
20, 123, 15, 16, 96, 0, 153, 243, 13, 60];

my $flate-dec = buf8.new: [1, 0, 16, 0, 1, 2, 229, 0, 1, 4, 6, 0, 1, 5, 166, 0,
1, 10, 83, 0, 1, 13, 114, 0, 1, 16, 148, 0, 1, 19, 175, 0, 1, 22, 24,
0, 1, 24, 248, 0, 1, 27, 158, 0, 1, 30, 67, 0, 1, 32, 253, 0, 1, 43,
108, 0, 1, 69, 44, 0, 1, 76, 251, 0, 1, 134, 199, 0, 1, 0, 116, 0, 2,
0, 217, 0, 2, 0, 217, 1, 2, 0, 217, 2, 2, 0, 217, 3, 2, 0, 217, 4, 2,
0, 217, 5, 2, 0, 217, 6, 2, 0, 217, 7, 2, 0, 217, 8, 2, 0, 217, 9, 2,
0, 217, 10, 2, 0, 217, 11, 2, 0, 217, 12, 2, 0, 217, 13, 2, 0, 217,
14, 2, 0, 217, 15, 2, 0, 217, 16, 2, 0, 217, 17, 1, 1, 239, 0];

%dict = :Filter<FlateDecode>, :DecodeParms{ :Predictor(12), :Columns(4) };

is-deeply my $result=LibGnuPDF::Filter.decode($flate-enc, :%dict),
    $flate-dec, "Flate with PNG predictors - decode";

my $re-encoded = LibGnuPDF::Filter.encode($result, :%dict);

is-deeply LibGnuPDF::Filter.decode($re-encoded, :%dict), $flate-dec, "Flate with PNG predictors - encode/decode round-trip";

done-testing;
