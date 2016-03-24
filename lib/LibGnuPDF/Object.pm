use v6;

module LibGnuPDF::Object {
    use LibGnuPDF :types, :subs, :find-lib;
    use NativeCall;

    our sub pdf_hash_new(CArray[pdf_error_t])
        returns pdf_hash_t
        is export(:subs, :DEFAULT)
        is native(&find-lib) { * }

    proto sub to-pdf-obj($) is export(:subs, :DEFAULT) { * };

    multi sub to-pdf-obj(Hash $h) {
	my pdf_hash_t $obj = pdf-check(&pdf_hash_new);
    }
}
