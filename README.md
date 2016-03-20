perl6-LibGnuPDF
----------------
This package contains bindings to the GnuPDF Library

At this stage, it concentrates on exposing Stream Filter and Encryption functionality
the aim of boosting PDF-tools performance.

```
use LibGnuPDF;
my Str $in = 'Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure.';

my buf8 $a85-encoded = pdf_stm_f_a85enc_get($in.encode("latin-1"));
my buf8 $a85-decoded = pdf_stm_f_a85enc_get($a85-encoded);

say a85-encoded.decode("latin-1");
```
