use v6;

class LibGnuPDF::Filter {

    use LibGnuPDF :types, :subs;
    use LibGnuPDF::Object :subs;
    use NativeCall;

    has pdf_stm_t $.filter is required;

    method filter-spec( Str $filter-name is copy ) {

        constant %Filters = %(
            ASCIIHexDecode  => { :dec(PDF_STM_FILTER_AHEX_DEC), :enc(PDF_STM_FILTER_AHEX_ENC) },
            ASCII85Decode   => { :dec(PDF_STM_FILTER_A85_DEC), :enc(PDF_STM_FILTER_A85_ENC) },
            CCITTFaxDecode  => { :dec(PDF_STM_FILTER_CCITTFAX_DEC), :enc(PDF_STM_FILTER_CCITTFAX_ENC) },
            Crypt           => {},
            DCTDecode       => { :dec(PDF_STM_FILTER_DCT_DEC), :enc(PDF_STM_FILTER_DCT_ENC) },
            FlateDecode     => { :dec(PDF_STM_FILTER_FLATE_DEC), :enc(PDF_STM_FILTER_FLATE_ENC), :predictors },
            LZWDecode       => { :dec(PDF_STM_FILTER_LZW_DEC), :enc(PDF_STM_FILTER_LZW_ENC),     :predictors },
            JBIG2Decode     => { :dec(PDF_STM_FILTER_JBIG2_DEC), :enc(PDF_STM_FILTER_JBIG2_ENC) },
            JPXDecode       => { :dec(PDF_STM_FILTER_JPX_DEC), :enc(PDF_STM_FILTER_JPX_ENC) },
            RunLengthDecode => { :dec(PDF_STM_FILTER_RL_DEC), :enc(PDF_STM_FILTER_RL_ENC) },
            );

        # See [PDF 1.7 Table H.1 Abbreviations for standard filter names]
        constant %FilterAbbreviations = %(
            AHx => 'ASCIIHexDecode',
            A85 => 'ASCII85Decode',
            LZW => 'LZWDecode',
            Fl  => 'FlateDecode',
            RL  => 'RunLengthDecode',
            CCF => 'CCITTFaxDecode',
            DCT => 'DCTDecode',
            );

        $filter-name = %FilterAbbreviations{$filter-name}
            if %FilterAbbreviations{$filter-name}:exists;

        die "unknown filter: $filter-name"
            unless %Filters{$filter-name}:exists;

        my $spec = %Filters{$filter-name};
	for <dec enc> {
	    $spec{'can-' ~ $_} //= $spec{$_}:exists
				    ?? ? pdf_stm_supported_filter_p($spec{$_})
				    !! False;
	}
	$spec;
    }

    # object may have an array of filters PDF 1.7 spec Table 3.4 
    multi method encode-filters( Hash :$dict! where .<Filter>.isa(List)) {
	if $dict<DecodeParms>:exists {
            die "Filter array {.<Filter>} does not have a corresponding DecodeParms array"
                if $dict<DecodeParms>:exists
                && (!$dict<DecodeParms>.isa(List) || +$dict<Filter> != +$dict<DecodeParms>);
        }

        for $dict<Filter>.keys.reverse -> $i {
            my %dict = Filter => $dict<Filter>[$i];
            %dict<DecodeParms> = %( $dict<DecodeParms>[$i] )
                if $dict<DecodeParms>:exists;

            $.encode-filters( :%dict )
        }

    }

    # object may have an array of filters PDF 1.7 spec Table 3.4 
    multi method encode-filters( Hash :$dict! where { .<Filter>:exists }) {
	my $spec = $.filter-spec( $dict<Filter> );
	die "unsupported encoding filter: $dict<Filter>"
	    unless $spec<can-enc>;
	my pdf_hash_t $params = $dict<DecodeParms>:exists
				  ?? LibGnuPDF::Object::to-hash( $dict<DecodeParms> )
				  !! pdf-check(&pdf_hash_new);
	pdf-check(&pdf_stm_install_filter, $.filter, $spec<enc>, $params);
	if $spec<predictor> && $dict<DecodeParms> && $dict<DecodeParms><Predictor> {
	    pdf-check(&pdf_stm_install_filter, $.filter, PDF_STM_FILTER_PRED_ENC, $params);
	}
    }

    method encoded(CArray $input) {
	my buf8 $out .= new;
	my $buf = CArray[pdf_uchar_t].new;
        $buf[1024] = 0;
	my $bytes = CArray[pdf_size_t].new;
	$bytes[0] = 0;
my UInt $more = 1;
	do {
	    $more = pdf-check(&pdf_stm_read, $!filter, $buf, $buf.elems-1, $bytes);
	    $out.append: $buf.head($bytes[0])
		if $bytes[0];
	}
	$out;
    }
	
    proto method encode($, Hash :$dict!) {*}

    multi method encode( $input, Hash :$dict! where !.<Filter>.defined) {
        # nothing to do
        $input;
    }
    multi method encode(Str $input, |c) {
	warn :$input.perl;
	my $buffer = CArray[pdf_uchar_t].new( $input.encode("latin-1" ));
	$.encode($buffer, |c);
    }

    multi method encode( $input, Hash :$dict! ) {
	my $filter = pdf-check(&pdf_stm_mem_new,
			       $input, $input.elems,
			       0, PDF_STM_READ);

	my $obj = self.new(:$filter);
	$obj.encode-filters( :$dict );
	$obj.encoded($input);
    }

    #----
    multi method decode-filters( Hash :$dict! where .<Filter>.isa(List)) {
	if $dict<DecodeParms>:exists {
            die "Filter array {.<Filter>} does not have a corresponding DecodeParms array"
                if $dict<DecodeParms>:exists
                && (!$dict<DecodeParms>.isa(List) || +$dict<Filter> != +$dict<DecodeParms>);
        }

        for $dict<Filter>.keys -> $i {
            my %dict = Filter => $dict<Filter>[$i];
            %dict<DecodeParms> = %( $dict<DecodeParms>[$i] )
                if $dict<DecodeParms>:exists;

            $.decode-filters( :%dict )
        }

    }

    # object may have an array of filters PDF 1.7 spec Table 3.4 
    multi method decode-filters( Hash :$dict! where { .<Filter>:exists }) {
	my $spec = $.filter-spec( $dict<Filter> );
	die "unsupported decoding filter: $dict<Filter>"
	    unless $spec<can-dec>;
	my pdf_hash_t $params = $dict<DecodeParms>:exists
				  ?? LibGnuPDF::Object::to-hash( $dict<DecodeParms> )
				  !! pdf-check(&pdf_hash_new);
	if $spec<predictor> && $dict<DecodeParms> && $dict<DecodeParms><Predictor> {
	    pdf-check(&pdf_stm_install_filter, $.filter, PDF_STM_FILTER_PRED_DEC, $params);
	}
	pdf-check(&pdf_stm_install_filter, $.filter, $spec<dec>, $params);
    }

    method decoded(CArray $input) {
	my buf8 $out .= new;
	my $buf = CArray[pdf_uchar_t].new;
        $buf[1024] = 0;
	my $bytes = CArray[pdf_size_t].new;
	$bytes[0] = 0;
	my UInt $more = 1;
	do {
	    $more = pdf-check(&pdf_stm_read, $!filter, $buf, $buf.elems-1, $bytes);
	    $out.append: $buf.head($bytes[0])
		if $bytes[0];
	}
	$out;
    }
	
    proto method decode($, Hash :$dict!) {*}

    multi method decode( $input, Hash :$dict! where !.<Filter>.defined) {
        # nothing to do
        $input;
    }
    multi method decode(Str $input, |c) {
	$.decode( $input.decode("latin-1"), |c);
    }
    multi method decode(Buf $input, |c) {
	warn :$input.perl;
	my $buffer = CArray[pdf_uchar_t].new( $input );
	$.decode($buffer, |c);
    }

    multi method decode( $input, Hash :$dict! ) {
	my $filter = pdf-check(&pdf_stm_mem_new,
			       $input, $input.elems,
			       0, PDF_STM_READ);

	my $obj = self.new(:$filter);
	$obj.decode-filters( :$dict );
	$obj.decoded($input);
    }


}
