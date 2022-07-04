module pdf
import x.ttf
import os
import strings
import compress.zlib
/******************************************************************************
*
* TTF font management
*
******************************************************************************/
[heap]
struct TtfFontRsc {
pub mut:
	id_font_file int
	id_font int
	id_font_desc int

	tf ttf.TTF_File
	font_name_id int
	font_name string
	full_name string

	pdf_font_id int
	pdf_font_descriptor_id int
	pdf_ttffont_file_id int

	flags u16
	first_char int = 1
	last_char int
	widths []int
	fontbbox []int
	ascent int
	descent int
}


/*
fn get_ttf_widths(mut tf ttf.TTF_File) []int {
	count := tf.glyph_count()
	mut widths := []int
	for i in 0..count {
		x_min, x_max, _, _ := tf.read_glyph_dim(i)
		widths << (x_max - x_min) * 0
	}
	return widths
}
*/

fn render_ttf_files(mut res_c strings.Builder, tf TtfFontRsc) ?int {
	buf := zlib.compress(tf.tf.buf)?
	res_c.write("${tf.id_font_file} 0 obj\n".bytes())?
	
	// mandatory fields in a compress obj stream
	res_c.write('<</Lenght1 ${tf.tf.buf.len} /Length ${buf.len+1} /Filter/FlateDecode>>\n'.bytes())?
	res_c.write('stream\n'.bytes())?
	res_c.write(buf)?
	res_c.write('\nendstream\n'.bytes())?
	res_c.write('endobj\n\n'.bytes())?
	return int(res_c.len)
}

fn render_ttf_font(mut res_c strings.Builder, tf TtfFontRsc) ?int {
	widths := pdf_format_width(tf.widths)?
	full_name := tf.full_name.replace(' ', '_')
	res_c.write("${tf.id_font} 0 obj\n".bytes())?
	res_c.write("<<
/Type/Font
/Name/${tf.font_name}
/Subtype/TrueType
/BaseFont/${full_name}
/Encoding/WinAnsiEncoding
/FirstChar ${tf.first_char}
/LastChar ${tf.last_char}
/FontDescriptor ${tf.id_font_desc} 0 R
/Widths${widths}
>>
endobj\n
".bytes())?
	return int(res_c.len)
}
// /Widths${widths}

fn render_ttf_font_decriptor(mut res_c strings.Builder, tf TtfFontRsc) ?int {
	full_name := tf.full_name.replace(' ', '_')
	fontbbox := pdf_format_width(tf.fontbbox)?
	res_c.write("${tf.id_font_desc} 0 obj\n".bytes())?
	res_c.write("<<
/Type/FontDescriptor
/FontName/${full_name}
/FontBBox${fontbbox}
/Flags ${tf.flags}
/Ascent ${tf.ascent}
/Descent ${tf.descent}
/StemV 80
/ItalicAngle 0
/FontFile2 ${tf.id_font_file} 0 R
>>
endobj\n
".bytes())?
	return int(res_c.len)
}

fn pdf_format_width(w []int) ?string {
	mut bs := strings.new_builder(4096)
	bs.write("[".bytes())?
	for x in w {
		bs.write(" $x".bytes())?
	}
	bs.write(" ]".bytes())?
	return bs.str()
}

pub fn (mut p Pdf) load_ttf_font(font_path string, font_name string, width_scale f32) {
	mut tf_rsc := TtfFontRsc{}

	tf_rsc.id_font_file = p.id_count + 1
	tf_rsc.id_font = p.id_count + 2
	tf_rsc.id_font_desc = p.id_count + 3
	p.id_count += 3

	mut tf := ttf.TTF_File{}
	tf.width_scale = width_scale
	tf.buf = os.read_bytes(font_path) or { panic(err) }
	println('TrueTypeFont file [$font_path] len: $tf.buf.len')
	tf.init()
	tf_rsc.tf = tf

	tf_rsc.flags = tf.flags
	//println("desc:\n${tf}")
	tf_rsc.fontbbox << int(tf.x_min)
	tf_rsc.fontbbox << int(tf.y_min)
	tf_rsc.fontbbox << int(tf.x_max)
	tf_rsc.fontbbox << int(tf.y_max)
	// println("FontBBox: ${tf_rsc.fontbbox}")
	tf_rsc.ascent = tf.ascent
	tf_rsc.descent = tf.descent

	tf_rsc.widths,tf_rsc.first_char,tf_rsc.last_char  = tf.get_ttf_widths()
	//tf_rsc.first_char = 1
	//tf_rsc.last_char = tf_rsc.widths.len
	
	//println("Widths ${tf_rsc.widths.len} :${tf_rsc.widths}")
	tf_rsc.font_name = font_name
	tf_rsc.full_name = tf.full_name

	p.ttf_font_used[font_name] = tf_rsc

	//tf_rsc.render_font() or {println("Error")}
}

/*
pub fn (mut p TtfFontRsc) render_object() string {
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