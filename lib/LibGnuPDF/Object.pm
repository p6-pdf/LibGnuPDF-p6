use v6;

module LibGnuPDF::Object {
    use LibGnuPDF :types, :subs, :find-lib;
    use NativeCall;

    our sub pdf_hash_new(CArray[pdf_error_t])
        returns pdf_hash_t
        is export(:subs, :DEFAULT)
        is native(&find-lib) { * }

    our sub pdf_hash_add_size(pdf_hash_t,
			 CArray[pdf_char_t],
			 pdf_size_t,
			 CArray[pdf_error_t]
			)
        returns pdf_bool_t
        is export(:subs, :DEFAULT)
        is native(&find-lib) { * }

    multi sub add-key(pdf_hash_t $h, Str $key, UInt $val) {
	my pdf_u32_t $uval = $val;
	my CArray[pdf_char_t] $ukey .= new(($key ~ 0.chr).encode: "utf-8");
	pdf-check(&pdf_hash_add_size, $h, $ukey, $uval);
    }

    multi sub add-key(pdf_hash_t $h, Str $key, $val) is default {
	die "unable to handle has key value: {$val.perl}";
    }

    our sub to-pdf-hash(Hash $h) is export(:subs, :DEFAULT) {
	my pdf_hash_t $pdf-hash = pdf-check(&pdf_hash_new);
	for $h.keys {
	    add-key($pdf-hash, $_, $h{$_});
	}
	$pdf-hash;
    }
}
