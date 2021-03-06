perl6-LibGnuPDF
----------------
This package contains:

- LibGnuPDF -  low level bindings to the GnuPDF Library.
- LibGnuPDF::Filter - implements a set of filter classess, compatible with PDF::Storage::Filter from the PDF::Tools distribution
- LibGnuPDF::Crypt - implements encryption and decryption objects, compatible with PDF::Storage::Crypt
- LibGnuPDF::Tie - binds Perl6 data to GnuPDF data objects (arrays, hashes etc)

At this stage, this module concentrates on exposing Stream Filter and Encryption functionality
the aim of boosting PDF-tools performance.

```
use LibGnuPDF::Filter;
my %dict = ( :Filter[ASCIIHexDecode Flate],
             :DecodeParms[ {}, { :BitsPerComponent(4), :Predictor(10), :Colors(3) } ],
    );
my $decoded = '100 100 Td (Hello, world!) Tj';
my $encoded = LibGnuPDF::Filter.encode($decoded, :%dict);
```
