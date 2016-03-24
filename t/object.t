use v6;
use LibGnuPDF :types;
use LibGnuPDF::Object :subs;
use Test;

my pdf_hash_t $hash-obj;

lives-ok {$hash-obj = to-pdf-obj( {} ) }, 'to-pdf-obj({}) - lives';
isa-ok $hash-obj, pdf_hash_t;

lives-ok {$hash-obj.destroy}, 'hash-obj.destroy - lives';

done-testing;


