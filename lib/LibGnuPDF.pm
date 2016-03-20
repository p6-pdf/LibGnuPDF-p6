use v6;

module LibGnuPDF {
    use NativeCall;
    use NativeCall::Types;

    sub find-lib {
	$*VM.platform-library-name('gnupdf'.IO).Str;
    }
    
    #| see pdf.h
    my constant pdf_bool_t is export(:types, :DEFAULT) = NativeCall::Types::bool;
    my constant pdf_char_t is export(:types, :DEFAULT) = uint8;
    my constant pdf_error_domain_t is export(:types, :DEFAULT) = NativeCall::Types::long;
    my constant pdf_size_t is export(:types, :DEFAULT) = NativeCall::Types::long;
    my constant pdf_hash_t is export(:types, :DEFAULT) = OpaquePointer;

    my constant pdf_error_t is export(:types, :DEFAULT) = OpaquePointer;
    my constant pdf_status_t is export(:types, :DEFAULT) = NativeCall::Types::long;
    my constant pdf_domain_t is export(:types, :DEFAULT) = NativeCall::Types::long;
    my constant pdf_message_t is export(:types, :DEFAULT) = Pointer[CArray[uint8]];

    our sub pdf_hash_new(Pointer[pdf_error_t])
        returns pdf_hash_t
        is native(&find-lib) { * }

    our sub pdf_error_get_status(pdf_error_t is rw)
        returns pdf_status_t
        is native(&find-lib) { * }

    our sub pdf_error_get_domain(pdf_error_t is rw)
        returns pdf_domain_t
        is native(&find-lib) { * }

    our sub pdf_error_get_message(pdf_error_t is rw)
        returns pdf_message_t
        is native(&find-lib) { * }
}
