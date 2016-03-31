use Test;

plan 6;

use LibGnuPDF::Filter;

use PDF::Grammar::PDF;
use PDF::Grammar::PDF::Actions;
use PDF::Storage::Input;
use PDF::Storage::IndObj;

my $actions = PDF::Grammar::PDF::Actions.new;

my $text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vitae enim non massa aliquet fringilla vitae non lacus. Aliquam dapibus auctor gravida. Donec malesuada a massa ut varius. Nullam rhoncus ex efficitur, tincidunt odio ac, ornare ligula. Integer eu sapien rhoncus orci posuere tristique. Vivamus finibus nisi urna, vel elementum lectus cursus vitae. Mauris malesuada pharetra risus, in molestie massa ullamcorper a. Mauris mollis, nulla in posuere mollis, turpis felis finibus ipsum, aliquet pulvinar elit tellus et leo. Pellentesque eget quam est. Sed commodo blandit libero quis dignissim. Curabitur sed euismod nulla, ut euismod massa. Sed blandit erat libero, sed ultricies lacus malesuada non. Quisque nec dapibus ligula.";

my $dict = { :Filter<LZWDecode>, };

my $encoded = LibGnuPDF::Filter.encode( $text, :$dict );
ok $encoded.elems < $text.chars, "text was compressed"
    or diag "plain-text:{$text.codes} bytes,  encoded:{$encoded.codes} bytes";
my $decoded = LibGnuPDF::Filter.decode( $encoded, :$dict );
is $decoded.decode("latin-1"), $text, "encode/decode round-trip";

my $input = 't/pdf/ind-obj-A85+LZW.in'.IO.slurp( :enc<latin-1> );
PDF::Grammar::PDF.parse($input, :$actions, :rule<ind-obj>)
    // die "parse failed";
my %ast = $/.ast;

$dict = { :Filter<ASCII85Decode LZWDecode>, };
$encoded = %ast<ind-obj>[2]<stream><encoded>;

lives-ok { $decoded = LibGnuPDF::Filter.decode( $encoded, :$dict ) }, 'basic content decode - lives';

my $encoded2;
lives-ok { $encoded2 = LibGnuPDF::Filter.encode( $decoded, :$dict ) }, 'basic content decode - lives';

my $decoded2;
lives-ok { $decoded2 = LibGnuPDF::Filter.decode( $encoded2, :$dict ) }, 'basic content decode - lives';

todo "issue #2";
is-deeply $decoded2, $decoded,
    q{basic LZW decompression - round trip};

