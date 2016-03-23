use v6;
use LibGnuPDF :types;
use LibGnuPDF::Filter;
use Test;

is-deeply LibGnuPDF::Filter.filter-spec('ASCIIHexDecode'), { :can-enc, :can-dec, :dec(PDF_STM_FILTER_AHEX_DEC), :enc(PDF_STM_FILTER_AHEX_ENC) }, 'ASCIIHexDecode spec';
is-deeply LibGnuPDF::Filter.filter-spec('AHx'), LibGnuPDF::Filter.filter-spec('ASCIIHexDecode'), 'AHx spec';
is LibGnuPDF::Filter.filter-spec('FlateDecode'), { :can-enc, :can-dec, :dec(PDF_STM_FILTER_FLATE_DEC), :enc(PDF_STM_FILTER_FLATE_ENC), :predictors }, 'FlateHexDecode spec';
is LibGnuPDF::Filter.filter-spec('Crypt'), { :!can-enc, :!can-dec, }, 'Crypt spec (nyi)';

dies-ok { LibGnuPDF::Filter.filter-spec('Wtf') }, 'unknown filter - dies';

done-testing;