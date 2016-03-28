use v6;

class LibGnuPDF::Filter {

    use NativeCall;
    use LibGnuPDF::Object :subs;
    use LibGnuPDF :types, :subs;

    has pdf_stm_t $.stream is required;

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

	$.predictor-filters( :!decode, |%($dict<DecodeParams>) )
	    if $spec<predictors> && $dict<DecodeParms>;
	pdf-check(&pdf_stm_install_filter, $.stream, $spec<enc>, pdf_hash_t);
    }

    method convert {
	my buf8 $out .= new;
	my $buf = CArray[pdf_uchar_t].new;
        $buf[1024] = 0;
	my $bytes = CArray[pdf_size_t].new;
	$bytes[0] = 0;
	my pdf_bool_t $more = 1;
	repeat {
	    $more = pdf-check(&pdf_stm_read, $!stream, $buf, $buf.elems-1, $bytes);
	    warn "more:$more bytes:$bytes[0]";
	    $out.append: $buf.head($bytes[0])
		if $bytes[0];
	} while $more;
	$out;
    }
	
    proto method encode($, Hash :$dict!) {*}

    multi method encode( $input, Hash :$dict! where !.<Filter>.defined) {
        # nothing to do
        $input;
    }
    
    multi method mem-stream(Str $input) {
	$.mem-stream($input.encode("latin-1" ));
    }

    multi method mem-stream(Blob $input) {
	$.mem-stream( CArray[pdf_uchar_t].new( $input ));
    }
    
    multi method mem-stream( CArray $input) {
	pdf-check(&pdf_stm_mem_new,
		  $input, $input.elems,
		  0, PDF_STM_READ);
    }

    multi method predictor-filters(
	Bool :$decode = False,
	UInt :$Predictor!,           #| predictor function
        UInt :$Columns = 1,          #| number of samples per row
        UInt :$Colors = 1,           #| number of colors per sample
        UInt :$BitsPerComponent = 8, #| number of bits per color
    ) {
						
	my pdf_hash_t $params = to-pdf-hash({
	    :$Predictor, :$Columns, :$Colors, :$BitsPerComponent
	});
	my $filter = $decode ?? PDF_STM_FILTER_PRED_DEC !! PDF_STM_FILTER_PRED_ENC;
	pdf-check(&pdf_stm_install_filter, $.stream, $filter, $params);
    }
    multi method predictor-filters(%*opt) is default {
    }

    multi method encode( $input, Hash :$dict! ) {
	my $stream = $.mem-stream( $input );
	my $obj = self.new(:$stream);
	$obj.encode-filters( :$dict );
	$obj.convert;
    }

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

	pdf-check(&pdf_stm_install_filter, $.stream, $spec<dec>, pdf_hash_t);
	$.predictor-filters( :decode, |%($dict<DecodeParms>) )
	    if $spec<predictors> && $dict<DecodeParms>;
    }

    proto method decode($, Hash :$dict!) {*}

    multi method decode( $input, Hash :$dict! where !.<Filter>.defined) {
        # nothing to do
        $input;
    }

    multi method decode( $input, Hash :$dict! ) {
	my $stream = $.mem-stream($input);
	my $obj = self.new(:$stream);
	$obj.decode-filters( :$dict );
	$obj.convert;
    }

    method prediction( $input, Bool :$decode = False, |c ) {
	my $stream = $.mem-stream($input);
	my $obj = self.new(:$stream);
	$obj.predictor-filters( :$decode, |c );
	$obj.convert;
    }

    method post-prediction( $input, |c ) {
	$.prediction( $input, :decode, |c );
    }


}
