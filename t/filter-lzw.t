use Test;

plan 2;

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

