use v6;

class LibGnuPDF::Filter {

    use LibGnuPDF :types, :subs;

    # chosen because, should have an underlying uint 8 representation and should stringfy
    # easily via :  ~$blob or $blob.Str

    proto method decode($, Hash :$dict!) {*}
    proto method encode($, Hash :$dict!) {*}

    multi method decode( $input, Hash :$dict! where !.<Filter>.defined) {
        # nothing to do
        $input;
    }

    # object may have an array of filters PDF 1.7 spec Table 3.4 
    multi method decode( $data is copy, Hash :$dict! where .<Filter>.isa(List)) {

        if $dict<DecodeParms>:exists {
            die "Filter array {.<Filter>} does not have a corresponding DecodeParms array"
                if $dict<DecodeParms>:exists
                && (!$dict<DecodeParms>.isa(List) || +$dict<Filter> != +$dict<DecodeParms>);
        }

        for $dict<Filter>.keys -> $i {
            my %dict = Filter => $dict<Filter>[$i];
            %dict<DecodeParms> = %( $dict<DecodeParms>[$i] )
                if $dict<DecodeParms>:exists;

            $data = $.decode( $data, :%dict )
        }

        $data;
    }

    multi method decode( $input, Hash :$dict! ) {
        my %params = %( $dict<DecodeParms> )
            if $dict<DecodeParms>:exists;
	my $spec = $.filter-spec( $dict<Filter> ).decode( $input, |%params);
	... # nyi
    }

    # object may have an array of filters PDF 1.7 spec Table 3.4 
    multi method encode( $data is copy, Hash :$dict! where .<Filter>.isa(List) ) {

        if $dict<DecodeParms>:exists {
            die "Filter array {.<Filter>} does not have a corresponding DecodeParms array"
                if $dict<DecodeParms>:exists
                && (!$dict<DecodeParms>.isa(List) || +$dict<Filter> != +$dict<DecodeParms>);
        }

        for $dict<Filter>.keys.reverse -> $i {
            my %dict = Filter => $dict<Filter>[$i];
            %dict<DecodeParms> = %( $dict<DecodeParms>[$i] )
                if $dict<DecodeParms>:exists;

            $data = $.encode( $data, :%dict )
        }

        $data;
    }

    multi method encode( $input, Hash :$dict! ) {
        my %params = %( $dict<DecodeParms> )
            if $dict<DecodeParms>:exists;
	my $spec = $.filter-spec( $dict<Filter> ).decode( $input, |%params);
	... # nyi
    }

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

}
