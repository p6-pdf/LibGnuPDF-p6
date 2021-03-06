use v6;

class X::LibGnuPDF::Error is Exception {
    has Str  $.message is required;
    has UInt $.domain;
    has UInt $.status;
    method message {"GnuPDF error: {$.message}"}
}

module LibGnuPDF {
    use NativeCall;
    use NativeCall::Types;

    sub find-lib is export(:find-lib) {
	$*VM.platform-library-name('gnupdf'.IO).Str;
    }

    my role PdfAlloced[&destroy-sub] {
	submethod DESTROY {
	    &destroy-sub(self);
	}
    }

    #| see pdf.h
    my constant pdf_bool_t is export(:types, :DEFAULT) = NativeCall::Types::bool;
    my constant pdf_domain_t is export(:types, :DEFAULT) = NativeCall::Types::long;
    my constant pdf_char_t is export(:types, :DEFAULT) = int8;
    my constant pdf_uchar_t is export(:types, :DEFAULT) = uint8;
    my constant pdf_u32_t is export(:types, :DEFAULT) = uint32;
    my constant pdf_error_domain_t is export(:types, :DEFAULT) = NativeCall::Types::long;

    our sub pdf_hash_destroy(OpaquePointer) is export(:subs, :DEFAULT) is native(&find-lib) { * }
    my constant pdf_hash_t is export(:types, :DEFAULT) = OpaquePointer but PdfAlloced[&pdf_hash_destroy];

    our sub pdf_error_destroy(ulong) is export(:subs, :DEFAULT) is native(&find-lib) { * }
    my constant pdf_error_t is export(:types, :DEFAULT) = ulong;# but PdfAlloced[&pdf_error_destroy];
    my constant pdf_message_t is export(:types, :DEFAULT) = Pointer[CArray[uint8]];
    my constant pdf_size_t is export(:types, :DEFAULT) = NativeCall::Types::long;

    my constant pdf_status_t is export(:types, :DEFAULT) = ulong;

    our sub pdf_stm_destroy(OpaquePointer) is export(:subs, :DEFAULT) is native(&find-lib) { * }
    my constant pdf_stm_t is export(:types, :DEFAULT) = OpaquePointer but PdfAlloced[&pdf_stm_destroy];

    our sub pdf_error_get_status(pdf_error_t)
        returns pdf_status_t
        is export(:subs, :DEFAULT)
        is native(&find-lib) { * }

    our sub pdf_error_get_domain(pdf_error_t)
        returns pdf_domain_t
        is export(:subs, :DEFAULT)
        is native(&find-lib) { * }

    our sub pdf_error_get_message(pdf_error_t)
        returns Str
        is export(:subs, :DEFAULT)
        is native(&find-lib) { * }

    # ----------- Streams ----------- #

    my Int enum pdf_stm_mode_E is export(:types, :DEFAULT) «
      :PDF_STM_UNKNOWN(-1)
      :PDF_STM_READ(0)
       PDF_STM_WRITE
    »;
    our constant PDF_STM_DEFAULT_CACHE_SIZE is export(:types, :DEFAULT) = 4096;
    my subset pdf_stm_mode_e of ulong where pdf_stm_mode_E;

    my Int enum pdf_stm_filter_type_E is export(:types, :DEFAULT) «
      :PDF_STM_FILTER_UNKNOWN(-1)
      :PDF_STM_FILTER_NULL(0)
       PDF_STM_FILTER_AHEX_ENC
       PDF_STM_FILTER_AHEX_DEC
       PDF_STM_FILTER_A85_ENC
       PDF_STM_FILTER_A85_DEC
       PDF_STM_FILTER_LZW_ENC
       PDF_STM_FILTER_LZW_DEC
       PDF_STM_FILTER_FLATE_ENC
       PDF_STM_FILTER_FLATE_DEC
       PDF_STM_FILTER_RL_ENC
       PDF_STM_FILTER_RL_DEC
       PDF_STM_FILTER_CCITTFAX_ENC
       PDF_STM_FILTER_CCITTFAX_DEC
       PDF_STM_FILTER_JBIG2_ENC
       PDF_STM_FILTER_JBIG2_DEC
       PDF_STM_FILTER_DCT_ENC
       PDF_STM_FILTER_DCT_DEC
       PDF_STM_FILTER_JPX_ENC
       PDF_STM_FILTER_JPX_DEC
       PDF_STM_FILTER_PRED_ENC
       PDF_STM_FILTER_PRED_DEC
       PDF_STM_FILTER_AESV2_ENC
       PDF_STM_FILTER_AESV2_DEC
       PDF_STM_FILTER_V2_ENC
       PDF_STM_FILTER_V2_DEC
       PDF_STM_FILTER_MD5_ENC
       PDF_STM_FILTER_LAST
    »;
    my subset pdf_stm_filter_type_e of ulong where pdf_stm_filter_type_E;
  
    our sub pdf_stm_supported_filter_p(pdf_stm_filter_type_e)
        returns pdf_bool_t
        is export(:subs, :DEFAULT)
        is native(&find-lib) { * }

    our sub pdf-check(&r, |c) is export(:subs, :DEFAULT) {
	my CArray[pdf_error_t] $error .= new(0);
	my $ret = &r(|c, $error);
	if $error[0] {
	    my Str $message = pdf_error_get_message($error[0]);
	    die $message;
	    my UInt $domain = pdf_error_get_domain($error[0]);
	    my UInt $status = pdf_error_get_status($error[0]);
	    my $stat = X::LibGnuPDF::Error.new( :$message, :$domain, :$status );
	    warn $stat.perl;
	    pdf_error_destroy($error[0]);
	    die $stat;
	}
	$ret;
    }

    multi sub trait_mod:<is>(Sub $r, :$pdf-checked!) {
	# experimental
	$r.wrap(-> |c { warn 'ooh checking...{$r.WHAT.gist}'; pdf-check($r, |c ) } );
    }
  
    our sub pdf_stm_mem_new(CArray[pdf_uchar_t] $buffer,
			    pdf_size_t $size,
			    pdf_size_t $cache-size,
			    pdf_stm_mode_e,
			    CArray[pdf_error_t]
		           )
        returns pdf_stm_t
        is export(:subs, :DEFAULT)
        is native(&find-lib) { * }

    our sub pdf_stm_get_mode(pdf_stm_t)
        returns ulong
        is export(:subs, :DEFAULT)
        is native(&find-lib) { * }

    our sub pdf_stm_install_filter(pdf_stm_t,
                                   pdf_stm_filter_type_e,
                                   pdf_hash_t,
                                   CArray[pdf_error_t])
        returns pdf_bool_t
        is export(:subs, :DEFAULT)
        is native(&find-lib) { * }

    our sub pdf_stm_read(pdf_stm_t,
                          CArray[pdf_uchar_t] $buf,
                          pdf_size_t          $bytes,
                          CArray[pdf_size_t]  $read-bytes,
                          CArray[Pointer])
        returns pdf_bool_t
        is export(:subs, :DEFAULT)
        is native(&find-lib) { * }

    our sub pdf_stm_write(pdf_stm_t,
                          CArray[pdf_uchar_t] $buf,
                          pdf_size_t          $bytes,
                          CArray[pdf_size_t]  $written-bytes,
                          CArray[Pointer])
        returns pdf_bool_t
        is export(:subs, :DEFAULT)
        is native(&find-lib) { * }

}


