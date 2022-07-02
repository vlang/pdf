module pdf
import x.ttf
import os
/******************************************************************************
*
* TTF font management
*
******************************************************************************/
[heap]
struct TttfFontRsc {
pub mut:
	tf ttf.TTF_File
	font_name_id int

	pdf_font_id int
	pdf_font_descriptor_id int
	pdf_ttffont_file_id int

	first_char int = 1
	last_char int = 255
	widths []int 
}

pub fn (mut p Pdf) load_ttf_font(font_path string, font_name string) {
	mut tf_rsc := TttfFontRsc{}
	mut tf := ttf.TTF_File{}
	tf.buf = os.read_bytes(font_path) or { panic(err) }
	println('TrueTypeFont file [$font_path] len: $tf.buf.len')
	tf.init()
	println('Unit per EM: $tf.units_per_em')
	tf_rsc.tf = tf

	p.ttf_font_used[font_name] = tf_rsc
}

/*
pub fn (mut p TttfFontRsc) render_object() string {
	return "
${pdf_font_id} 0 obj
<<
	/LastChar 255
	/BaseFont/GravitasOne
	/Type/Font
	/Subtype/TrueType
	/Encoding/WinAnsiEncoding
	/FirstChar 1
	/Widths[0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 369 445 468 722 863 908 911 268 478 478 509 522 399 524 396 461 878 572 802 797 751 809 824 750 817 824 396 399 398 526 398 752 1198 923 940 901 988 904 818 937 1093 604 641 1026 807 1078 911 952 901 952 991 863 849 924 878 1270 934 864 810 478 461 478 666 746 459 899 906 775 906 774 574 805 945 525 558 892 525 1356 945 824 920 906 773 761 604 932 765 1139 827 767 806 461 257 461 726 0 908 0 333 0 607 0 0 0 475 0 0 474 1290 0 0 0 0 333 333 602 602 475 637 1137 513 0 0 474 1189 0 0 0 369 445 775 895 674 864 257 724 459 873 582 743 617 524 873 459 466 523 542 515 459 932 678 396 459 408 558 743 955 1054 1015 752 923 923 923 923 923 923 1187 901 904 904 904 904 604 604 604 604 988 911 952 952 952 952 952 523 952 924 924 924 924 864 948 1013 899 899 899 899 899 899 1199 775 774 774 774 774 525 525 525 525 791 945 824 824 824 824 824 523 824 932 932 932 932 765 948 765]
	/FontDescriptor ${pdf_font_descriptor_id} 0 R
	>>
endobj
${pdf_font_descriptor_id} 0 obj
<<
	/CapHeight 691
	/FontBBox[-37 -326 1340 945]
	/Type/FontDescriptor
	/FontFile2 1 0 R
	/Descent -326
	/StemV 80
	/Flags 32
	/Ascent 945
	/FontName/GravitasOne
	/ItalicAngle 0
>>
	"
}
*/