module pdf

/**********************************************************************
*
* pdf writer V implementation
*
* Copyright (c) 2020 Dario Deledda. All rights reserved.
* Use of this source code is governed by an MIT license
* that can be found in the LICENSE file.
*
* Note:
* - All the internal values are treated as mm
*
* TODO:
**********************************************************************/
import compress.zlib
import strings
import math
// import os

/******************************************************************************
*
* General Utilities
*
******************************************************************************/

/******************************************************************************
*
* Obj Utilities
*
******************************************************************************/
// pub  // when in a module must be uncomented
pub struct Obj {
pub mut:
	id       int      // obj id
	ver      int      // version of the obj, default 0
	fields   []string // list of the fields of the obj
	parts    []string // list of all parts, these are before the txt field
	txt      string   // raw source content, it is used after the parts
	raw_data []u8

	is_stream bool // if true this object is a stream
	compress  bool // if true the stream will be compressed

	name string
}

pub fn (o Obj) render_obj(mut res_c strings.Builder) !int {
	// creat the parts of the object
	mut tmp_txt := strings.new_builder(32768)

	// write raw binary data
	if o.raw_data.len > 0 {
		return o.render_obj_bytes(mut res_c)
	} else {
		for txt in o.parts {
			tmp_txt.write(txt.bytes())!
		}

		if o.compress {
			return o.render_obj_cmpr(mut res_c, tmp_txt.str())
		} else {
			return o.render_obj_str(mut res_c, tmp_txt.str())
		}
	}
}

fn (o Obj) render_obj_bytes(mut res_c strings.Builder) !int {
	// obj ids
	res_c.write('$o.id $o.ver obj\n'.bytes())!

	// obj fields
	res_c.write('<< '.bytes())!
	for field in o.fields {
		res_c.write('$field '.bytes())!
	}
	if o.txt.len > 0 {
		res_c.write('/Length $o.raw_data.len'.bytes())!
	}
	res_c.write(' >>\n'.bytes())!
	if o.is_stream {
		res_c.write('stream\n'.bytes())!
	}
	res_c.write(o.raw_data)!
	if o.is_stream {
		res_c.write('\nendstream\n'.bytes())!
	}
	// obj end
	res_c.write('endobj\n\n'.bytes())!
	return int(res_c.len)
}

fn (o Obj) render_obj_str(mut res_c strings.Builder, txt_parts string) !int {
	// obj ids
	res_c.write('$o.id $o.ver obj\n'.bytes())!

	txt := o.txt + txt_parts

	// obj fields
	res_c.write('<< '.bytes())!
	for field in o.fields {
		res_c.write('$field '.bytes())!
	}
	if o.txt.len > 0 {
		res_c.write('/Length1 $txt.len/Length $txt.len'.bytes())!
	}
	res_c.write(' >>\n'.bytes())!

	// content
	if o.txt.len > 0 {
		if o.is_stream {
			res_c.write('stream\n'.bytes())!
		}
		res_c.write(txt.bytes())!
		if o.is_stream {
			res_c.write('\nendstream'.bytes())!
		}
		res_c.write('\n'.bytes())!
	}

	// obj end
	res_c.write('endobj\n\n'.bytes())!
	return int(res_c.len)
}

fn (o Obj) render_obj_cmpr(mut res_c strings.Builder, txt_parts string) !int {
	// obj ids
	res_c.write('$o.id $o.ver obj\n'.bytes())!

	// obj fields
	res_c.write('<< '.bytes())!
	for field in o.fields {
		res_c.write('$field '.bytes())!
	}

	// cmp_status := C.compress(buf.data, &cmp_len, charptr(txt.str), u32(txt.len))
	txt_buf := '$o.txt$txt_parts'
	buf := zlib.compress(txt_buf.bytes()) or { return error('compress failed') }

	// mandatory fields in a compress obj stream
	res_c.write('/Length1 $txt_buf.len'.bytes())!
	res_c.write('/Length $buf.len'.bytes())!
	res_c.write('/Filter/FlateDecode>>\n'.bytes())!
	res_c.write('stream\n'.bytes())!
	res_c.write(buf)!
	res_c.write('\nendstream\n'.bytes())!
	res_c.write('endobj\n'.bytes())!

	return int(res_c.len)
}

/******************************************************************************
*
* Page struct
*
******************************************************************************/
// default A4 page size
pub struct Box {
pub mut:
	x f32
	y f32
	w f32 = 595
	h f32 = 842
}

fn (box Box) str() string {
	return '$box.x $box.y $box.w $box.h'
}

pub const (
	// all the formats are expressed in millimeters
	page_fmt = {
		// ISO
		'A0':       Box{0, 0, 841, 1189}
		'B0':       Box{0, 0, 1000, 1414}
		'A1':       Box{0, 0, 594, 841}
		'B1':       Box{0, 0, 707, 1000}
		'A2':       Box{0, 0, 420, 594}
		'B2':       Box{0, 0, 500, 707}
		'A3':       Box{0, 0, 297, 420}
		'B3':       Box{0, 0, 353, 500}
		'A4':       Box{0, 0, 210, 297}
		'B4':       Box{0, 0, 250, 353}
		'A5':       Box{0, 0, 148, 210}
		'B5':       Box{0, 0, 176, 250}
		// american
		'letter':   Box{0, 0, 216, 279}
		'legal':    Box{0, 0, 216, 356}
		'legal jr': Box{0, 0, 203, 127}
		'tabloid':  Box{0, 0, 279, 432}
	}

	mm_unit   = 2.83464
	inch_unit = 72.0
	pdf_unit  = 1.0 // default for PDF manuals
)

pub struct Page {
pub mut:
	pdf               &Pdf = &Pdf(unsafe { nil }) // PDF, page owner
	content_obj_index int  = -1 // content object index
	page_obj_id       int      // obj id of the page
	obj_id_list       []int    // list of the page object
	resources         []string // resource strings
	fields            []string // additional fields for the page
	shaders           []string // Pattern and Shaders
	// user unit in 1/72 of inch
	// 1/72 = 0.35278 mm
	// to achive a unit in mm specify 1.0/0.35278 = 2.83464
	// to achive uni in inch specify 72
	user_unit f32 = 1.0
	// attributes
	media_box Box = Box{} // page size
	crop_box  Box = Box{} // default = media_box
	// draw variables
	border Box = Box{}
}

pub struct Page_params {
pub mut:
	user_unit f32    = 2.83464 // default mm in 1/72 of inch
	format    string = 'A4' // default fromat ISO A4
	media_box Box    = Box{0, 0, 0, 0} // default a not valid bbox
	// content params
	is_stream bool = true
	compress  bool
	// config param
	gen_content_obj bool
}

pub fn (mut p Pdf) create_page(params Page_params) int {
	// create a new object for the page
	obj := Obj{
		id: p.get_new_id()
	}
	p.obj_list << obj

	// set the page format from the format table
	// if a format is not found check if the box is initatied
	// else default is ISO A4
	mut box := pdf.page_fmt['A4']
	if params.format in pdf.page_fmt {
		// use a default format
		box = pdf.page_fmt[params.format]
		box.x *= pdf.mm_unit
		box.y *= pdf.mm_unit
		box.w *= pdf.mm_unit
		box.h *= pdf.mm_unit
	} else {
		// check if we have a valid media box
		sum := box.x + box.y + box.w + box.h
		if sum > 0.0 {
			box = params.media_box
			box.x *= params.user_unit
			box.y *= params.user_unit
			box.w *= params.user_unit
			box.h *= params.user_unit
		}
	}

	mut new_page := Page{
		pdf: p
		page_obj_id: obj.id
		media_box: box
		crop_box: box
		user_unit: params.user_unit
		// draw variables
		border: box
	}

	// check user unit, otherwise use pdf default mm
	if new_page.user_unit == 0 {
		new_page.user_unit = p.user_unit
	}

	// if set generate a content object
	if params.gen_content_obj {
		// create the page Content
		mut content := Obj{
			id: p.get_new_id()
			is_stream: params.is_stream
			compress: params.compress
		}

		// add the page Object to the PDF with its content
		p.obj_list << content
		new_page.content_obj_index = (p.obj_list.len - 1)
		new_page.obj_id_list << content.id
	}

	p.page_list << new_page
	return p.page_list.len - 1
}

pub fn (mut p Pdf) add_page_obj(mut pg Page, obj Obj) {
	p.obj_list << obj
	pg.obj_id_list << obj.id
	// println("len page list: ${pg.pdf.page_list.len}")
}

pub fn (mut p Page) push_content(txt string) bool {
	if p.content_obj_index >= 0 {
		p.pdf.obj_list[p.content_obj_index].txt += txt
		return true
	}
	return false
}

// set_unit set unit to use in the page
pub fn (mut p Page) set_unit(in_unit string) {
	match in_unit {
		'mm' {
			p.user_unit = 0.35278
		}
		'cm' {
			p.user_unit = 3.5278
		}
		'inch' {
			p.user_unit = 1.0
		}
		else {
			eprintln('unknown measurement unit')
		}
	}
}

// render_page render the page in the string builder and return the inital_displacement and page obj id
pub fn (mut p Pdf) render_page(mut res_c strings.Builder, pg Page, parent_id int) !Posi {
	obj_id := p.get_obj_index_by_id(pg.page_obj_id)
	mut obj := p.obj_list[obj_id]
	obj.fields << '/Type /Page'
	obj.fields << '/Parent $parent_id 0 R'

	// obj.fields << "/UserUnit ${pg.user_unit}" // default 1/72 of inch
	obj.fields << '/MediaBox  [ $pg.media_box.str() ]'
	obj.fields << '/CropBox   [ $pg.crop_box.str() ]'

	for field in pg.fields {
		obj.fields << field
	}

	// resources
	obj.fields << '/Resources  <<  /ProcSet  [/PDF/ImageB/ImageC/ImageI/Text] '
	// Color space
	obj.fields << '/Group<</S/Transparency/CS/DeviceRGB/I true>>'
	for rsrc in pg.resources {
		obj.fields << rsrc
	}

/*
	// add the base fonts in use to each the page resources
	for _, x in p.base_font_used {
		obj.fields << '/Font  <<  /F$x.font_name_id  $x.obj_id 0 R  >> '
	}

	// add the TTF fonts
	for name, tf in p.ttf_font_used {
		obj.fields << '/Font  <<  /$name  ${tf.id_font} 0 R  >> '
	}
*/

	// add the base fonts in use to each the page resources
	if p.base_font_used.len + p.ttf_font_used.len > 0 {		
		mut txt := "/Font  <<"
		// add the base fonts in use to each the page resources
		for _, x in p.base_font_used {
			txt += '/F$x.font_name_id  $x.obj_id 0 R '
		}
		// add the TTF fonts
		for name, tf in p.ttf_font_used {
			txt += '/$name ${tf.id_font} 0 R '
		}

		txt += ">>"
	
		obj.fields <<  txt
	}

	//" /Shading << /Sh_${name} ${index} 0 R >> "
	// shaders
	if pg.shaders.len > 0 {
		obj.fields << '/Shading <<'
		for shader in pg.shaders {
			obj.fields << shader
		}
		obj.fields << '>> '
	}

	obj.fields << '>> '

	// Contents
	obj.fields << '/Contents  ${pg.obj_id_list[0]} 0 R'

	// save displacement a obj id of the page
	posi := Posi{res_c.len, obj.id}

	obj.render_obj(mut res_c)!
	return posi
}

/******************************************************************************
*
* PDF struct
*
******************************************************************************/
// used to mantain the base font iformation in order to write the used resources for every page in the pdf
struct BaseFontRsc {
	font_name_id int
	obj_id       int
}



[heap]
pub struct Pdf {
pub mut:
	obj_list       []Obj  = []Obj{} // list of all the object sof the pdf
	page_list      []Page = []Page{} // list of all the pages struct, these are not the page Objects of the pdf
	base_font_used map[string]BaseFontRsc // contains all the base font used in the pdf
	ttf_font_used map[string]TtfFontRsc  // contains all the ttf font used in the pdf
	id_count       int // id used to count the added obj
	// utility data
	u_to_glyph_table map[string]string // map from unicode to postscritpp glyph
	user_unit        f32 = 2.83464 // default mm in 1/72 of inch, inherit from pages if not specified
}

// init_afm_metrics init the unicode to postscritpp glyph map
fn (mut p Pdf) init_afm_metrics() {
	for k, v in glyp_unicode {
		p.u_to_glyph_table[v.str()] = k
	}
}

pub fn (mut p Pdf) init() {
	// catalog id 1
	mut cat := Obj{
		id: 1
	}
	cat.fields << '/Type /Catalog'
	cat.fields << '/Pages  2 0 R'
	//cat.fields << '/Metadata  3 0 R'
	// cat.fields << "/Outlines  3 0 R"
	p.obj_list << cat

	// page index id 2
	mut pindx := Obj{
		id: 2
	}
	pindx.fields << '/Type /Pages'
	p.obj_list << pindx
	p.id_count = 2
/*
	// Metadata
	mut metadata := Obj{
		id: 3
	}

	metadata_str := '<?xpacket begin="ï»¿" id="W5M0MpCehiHzreSzNTczkc9d"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XMP Core 4.1.1">
	<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
		<rdf:Description rdf:about=""
				xmlns:xap="http://ns.adobe.com/xap/1.0/">
			<xap:ModifyDate>2022-07-04T23:09:34+02:00</xap:ModifyDate>
		</rdf:Description>
	</rdf:RDF>
</x:xmpmeta>
<?xpacket end="w"?>'
	metadata.fields << '/Type /Metadata /Subtype /XML /Length ${metadata_str.len}'
	metadata.raw_data = metadata_str.bytes()
	metadata.is_stream = true
	p.obj_list << metadata
	p.id_count = 3
*/
	/*
	// outlines id 3
	mut outlines := Obj{id:3}
	outlines.fields << "/Type /Outlines"
	outlines.fields << "/Count  0"
	p.obj_list << outlines

	p.id_count = 3
	*/
	//
	// Init the afm_metrics for glyph
	//
	p.init_afm_metrics()
}

// get_new_id generate a new id for the objects of the pdf, must be call to obtain a valid id for a new object
pub fn (mut p Pdf) get_new_id() int {
	p.id_count++
	return p.id_count
}

// get_obj_index_by_id retrive an object using its object id
pub fn (p Pdf) get_obj_index_by_id(id int) int {
	for c, o in p.obj_list {
		if o.id == id {
			return c
		}
	}
	return -1 // not found
}

// get_obj_by_name retrive an object using its object name
pub fn (p Pdf) get_obj_index_by_name(name string) int {
	for c, o in p.obj_list {
		if o.name == name {
			return c
		}
	}
	return -1 // not found
}

// utility struct, used to store the dispalcement of the objects in order to create the Xref table of the pdf
pub struct Posi {
pub mut:
	pos int
	id  int
}

// render the pdf document to a string.Builder
pub fn (mut p Pdf) render() !strings.Builder {
	mut posi := []Posi{}
	mut rendered := []int{} // rendered ids
	mut res := strings.new_builder(32768)
	res.write('%PDF-1.4\n'.bytes())! // format
	res.write('%äüöß\n\n'.bytes())! // format
	mut count := 1

	// catalog
	posi << Posi{res.len, count}
	rendered << count
	count++
	// res.write(p.obj_list[0].render_obj(res))
	p.obj_list[0].render_obj(mut res)!

	// Pages
	mut pl_obj := p.obj_list[1]
	mut page_list := strings.new_builder(128)
	for pg in p.page_list {
		page_list.write('$pg.page_obj_id 0 R '.bytes())!
	}
	tmp_str := page_list.str()
	pl_obj.fields << ' /Kids['
	pl_obj.fields << tmp_str
	pl_obj.fields << ']'
	pl_obj.fields << ' /Count $p.page_list.len'
	posi << Posi{res.len, count}
	rendered << count
	count++
	// res.write(pl_obj.render_obj())
	pl_obj.render_obj(mut res)!

	/*
	// outlines
	res.write(p.obj_list[2].render_obj())
	rendered << 3
	*/
	
	// TTF Fonts
	for _, tf_rsc in p.ttf_font_used {
		// println("Rendering font [${k}]")
		
		posi << Posi{res.len, tf_rsc.id_font_file}
		rendered << tf_rsc.id_font_file
		render_ttf_files(mut res, tf_rsc) or {
			eprintln("Font file render failed!")
			continue
		}
				
		posi << Posi{res.len, tf_rsc.id_font}
		rendered << tf_rsc.id_font
		render_ttf_font(mut res, tf_rsc) or {
			eprintln("Font render failed!")
			continue
		}

		posi << Posi{res.len, tf_rsc.id_font_desc}
		rendered << tf_rsc.id_font_desc
		render_ttf_font_decriptor(mut res, tf_rsc) or {
			eprintln("Font descriptor render failed!")
			continue
		}
	}


	// render pages
	for pg in p.page_list {
		posi_tmp := p.render_page(mut res, pg, pl_obj.id)!

		// save the byte displacement of the page we rendered
		posi << posi_tmp
		rendered << posi_tmp.id
	}

	// render all other objs
	for obj in p.obj_list {
		if obj.id in rendered {
			continue
		}
		posi << Posi{res.len, obj.id}
		rendered << obj.id
		obj.render_obj(mut res)!
	}

	// render xref
	// TODO: do a better dorting, now it is very scarce!!
	start_xref := res.len
	res.write('xref\n'.bytes())!
	res.write('0 1\n'.bytes())!
	//res.write('0 ${posi.len + 1}\n'.bytes())!
	res.write('0000000000 65535 f \n'.bytes())!

	mut ids := posi.map(int(it.id))
	ids.sort()

	for x in ids {
		for row in posi {
			if row.id == x {
				res.write('$row.id 1\n'.bytes())!
				res.write('${row.pos:010d} 00000 n \n'.bytes())!
				//res.write('${row.pos:010d} 00000 n\r\n'.bytes())!
				break
			}
		}
	}

	// trailer
	res.write('trailer\n'.bytes())!
	res.write('<</Size ${posi.len + 1}/Root 1 0 R /ID [<00000000000000000000000000000000> <00000000000000000000000000000000>]>>\n'.bytes())!

	res.write('startxref\n'.bytes())!
	res.write(start_xref.str().bytes())!
	res.write('\n%%EOF\n'.bytes())!
	return res
}

/******************************************************************************
*
* Color
*
******************************************************************************/
pub struct RGB {
pub mut:
	r f32
	g f32
	b f32
}

/******************************************************************************
*
* Base Font resources
*
******************************************************************************/
// get_base_font_list retrive the list of usable base fonts in a pdf
pub fn get_base_font_list() []string {
	return base_font_params.keys()
}

// use_base_font specify a base font that must be used in the pdf
pub fn (mut p Pdf) use_base_font(font_name string) bool {
	if font_name in base_font_params.keys() {
		// add default PDF font, no need to include it
		mut font_obj := Obj{
			id: p.get_new_id()
		}

		// for now we use the array position as index
		font_name_id := p.base_font_used.len

		font_obj.fields << '/Name /F$font_name_id /Type /Font /Subtype /Type1 /BaseFont /$font_name /Encoding /MacRomanEncoding'
		p.obj_list << font_obj
		p.base_font_used[font_name] = BaseFontRsc{
			font_name_id: font_name_id
			obj_id: font_obj.id
		}
		return true
	}
	return false
}

pub fn (mut p Pdf) get_base_font_id(font_name string) string {
	mut res := ''
	if font_name in p.base_font_used {
		res = "F${p.base_font_used[font_name].font_name_id}"
	}
	return res
}

/******************************************************************************
*
* JPEG resources
*
******************************************************************************/
// get_jpeg_info get the width,height and number of bit per pixel of a jpeg file
pub fn get_jpeg_info(data []u8) (int, int, int) {
	// cehck for empty
	if data.len <= 0 {
		return 0, 0, 0
	}

	mut i := 0
	for i < (data.len - 1) {
		if data[i] == 0xff && (data[i + 1] == 0xc0 || data[i + 1] == 0xc2) {
			i += 2
			// length := (int(data[i]) << 8) | int(data[i + 1])
			i += 2
			n_bit := data[i]
			i++
			height := (u16(data[i]) << 8 | data[i + 1])
			i += 2
			width := (u16(data[i]) << 8 | data[i + 1])
			i += 2
			// println("get jped params l: $length nbit: $n_bit w:[$width] h:[$height].")
			return n_bit, width, height
		}
		i++
	}
	return 0, 0, 0
}

// add_jpeg_resource add a jpeg as resource to the pdf
pub fn (mut p Pdf) add_jpeg_resource(jpeg_data []u8) int {
	jpg_n_bit, jpg_w, jpg_h := get_jpeg_info(jpeg_data)
	mut jpeg_obj := Obj{
		id: p.get_new_id()
		is_stream: true
	}
	jpeg_obj.fields << '/Type/XObject/Subtype/Image /Width $jpg_w /Height $jpg_h /BitsPerComponent $jpg_n_bit /ColorSpace/DeviceRGB/Filter/DCTDecode/Length $jpeg_data.len'
	jpeg_obj.raw_data = jpeg_data
	p.obj_list << jpeg_obj
	return jpeg_obj.id
}

// use_jpeg specify that the jpeg with jpeg_id is used in the page
pub fn (mut p Page) use_jpeg(jpeg_id int) {
	p.resources << '/XObject<</Image$jpeg_id $jpeg_id 0 R>>'
}

pub fn (mut pg Page) draw_jpeg(jpeg_id int, bx Box) string {
	x := bx.x * pg.user_unit
	y := pg.media_box.h - (bx.y * pg.user_unit)
	w := bx.w * pg.user_unit
	h := bx.h * pg.user_unit

	return '
q
$w 0 0 $h $x $y cm
/Image$jpeg_id Do
Q
'
}

/******************************************************************************
*
* Text
*
******************************************************************************/
pub enum Text_align {
	left
	center
	right
	justify
}

pub struct Text_params {
pub mut:
	font_size    f32 = 12.0
	font_name    string
	font_color_c string
	font_color_f string
	render_mode  int = -1
	word_spacing f32
	leading      f32 = 0.1 // in proportion of the font size
	// transformation matrix
	tm00 f32
	tm10 f32
	tm01 f32
	tm11 f32
	// text allign
	text_align Text_align = .left
	// color
	s_color RGB = RGB{-1, 0, 0}
	f_color RGB = RGB{-1, 0, 0}
}

// return the increment of Y for next line
pub fn (mut pg Page) new_line_offset(fnt_params Text_params) f32 {
	return f32(fnt_params.font_size + fnt_params.font_size * fnt_params.leading) / pg.user_unit
}

// clean_string clean form round brackets and backslash for PDF string standard
pub fn clean_pdf_string(txt string) string {
	return txt.replace_each(['(', '\\(', ')', '\\)', '\\', '\\\\'])
}

pub fn (mut tp Text_params) scale(x_scale f32, y_scale f32) {
	tp.tm00 = x_scale
	tp.tm11 = y_scale
}

fn (pg Page) get_text_parms(x f32, y f32, params Text_params) (string, string, string, string, string, string) {
	x1 := x * pg.user_unit
	y1 := pg.media_box.h - (y * pg.user_unit)

	mut font_id := "F1" 
	if params.font_name in pg.pdf.ttf_font_used {
		font_id = params.font_name
	} else {
		font_id = "F${pg.pdf.base_font_used[params.font_name].font_name_id}"
	}

	redender_mode := if params.render_mode >= 0 { '$params.render_mode Tr\n' } else { '' }
	word_spacing := if params.word_spacing > 0 {
		'${params.word_spacing * pg.user_unit} Tw\n'
	} else {
		''
	}
	txt_matrix := if params.tm00 != 0.0 {
		'$params.tm00 $params.tm01 $params.tm10 $params.tm11 $x1 $y1 Tm\n'
	} else {
		'$x1 $y1 Td\n'
	}

	stroke_color := if params.s_color.r < 0 {
		''
	} else {
		'$params.s_color.r $params.s_color.g $params.s_color.b RG '
	}
	fill_color := if params.f_color.r < 0 {
		''
	} else {
		'$params.f_color.r $params.f_color.g $params.f_color.b rg '
	}

	return font_id, redender_mode, word_spacing, txt_matrix, stroke_color, fill_color
}

// draw_raw_text draw a simple raw string at the x,y coordinates with the text parameters params.
// The string is passed directly to the 'TJ' pdf command without filtering.
// To draw a simple string you must write it  (your text) with round brackets around the text.
// For further information have a look af the PDF standard for TJ command
pub fn (pg Page) draw_raw_text(in_txt string, x f32, y f32, params Text_params) string {
	font_id, redender_mode, word_spacing, 
	txt_matrix, stroke_color, fill_color := pg.get_text_parms(x , y, params)

	return '
BT
/${font_id} $params.font_size Tf
$stroke_color$fill_color$txt_matrix$redender_mode${word_spacing}[${in_txt}]TJ
ET
'
}
// draw_base_text draw a simple string at the x,y coordinates with the text parameters params
// optional you can use PDF Literal string 3-byte UTF-8 BOM: (\357\273\277 ... )
pub fn (pg Page) draw_base_text(in_txt string, x f32, y f32, params Text_params) string {
	return pg.draw_raw_text('(${clean_pdf_string(in_txt)})', x , y, params)
}


// draw_unicode_text draw a simple raw string at the x,y coordinates with the text parameters params.
// The string is composed by the bytes of the utf8 chars:
// '€ABC' must be written as the following string '80 41 42 43'
// The conversion in sequence of bystes as string is up to the user
pub fn (pg Page) draw_unicode_text(in_txt string, x f32, y f32, params Text_params) string {
	mut res := strings.new_builder(in_txt.len * 3 + 2)

	res.write_string('<')
	for byte_val in in_txt.bytes() {
		res.write_string(' ${byte_val:02X}') 
	}
	res.write_string(' >')
	return pg.draw_raw_text(res.str(), x, y, params)
}

// calc_word_spacing calculate the sapcing to add to the space char 0x20 to fill the row only if txt fill al least half of teh horizontal space of the box.w
pub fn (pg Page) calc_word_spacing(txt string, in_box Box, in_params Text_params) f32 {
	mut params := in_params
	mut tmp_width, _, _ := pg.calc_string_bb(txt, in_params)

	// if the width is less then the half do not calculate space
	if tmp_width <= (in_box.w * 0.75) {
		return params.word_spacing
	}

	n_space := txt.count(' ')
	if n_space <= 0 {
		return params.word_spacing
	}
	return (in_box.w - tmp_width) / n_space
}

// text_box draw a text inside a box, return true if the text fit in the box, otherwise false and the leftover text and the last used y coordinate
pub fn (mut pg Page) text_box(txt string, in_box Box, in_params Text_params) (bool, string, f32) {
	mut params := in_params

	mut box := Box{in_box.x, in_box.y, in_box.w, in_box.h}
	row_height := (params.font_size + params.font_size * params.leading) / pg.user_unit

	// draw bb
	// pg.push_content("1.0  0.0  0.0  RG\n")
	// pg.push_content(pg.draw_rect(box))

	// align flag multiplier
	right_align := if params.text_align == .right { 1 } else { 0 }
	center_align := if params.text_align == .center { 1 } else { 0 }

	mut y := box.y + row_height
	rows := txt.split_into_lines()
	for c, row in rows {
		mut tmp_row := row

		// skip empty rows
		if tmp_row.trim_space().len < 2 {
			y += row_height
			continue
		}

		mut tmp_width, _, _ := pg.calc_string_bb(tmp_row, params)

		// the row is shorter than the box width
		if tmp_width <= box.w {
			if params.text_align == .justify {
				tmp_ws := params.word_spacing
				params.word_spacing = pg.calc_word_spacing(tmp_row, box, params)
				pg.push_content(pg.draw_base_text(tmp_row, box.x, y, params))
				params.word_spacing = tmp_ws
			} else {
				pg.push_content(pg.draw_base_text(tmp_row, box.x +
					(box.w - tmp_width) * right_align + center_align * (box.w - tmp_width) * 0.5,
					y, params))
			}
			y += row_height
			if y > (box.y + box.h) {
				if c + 1 == rows.len {
					pg.push_content('0 Tw\n')
					return true, '', y
				}
				// println("Too much text! [FL]")
				leftover_text := rows[c + 1..].join('\n')
				pg.push_content('0 Tw\n')
				return false, leftover_text, y
			}

			// the row is longer than the box width, we need to cut it
		} else {
			mut words_list := row.split(' ')
			mut l := words_list.len
			for l > 0 {
				tmp_txt := words_list[..l].join(' ').trim_space()
				tmp_width, _, _ = pg.calc_string_bb(tmp_txt, params)
				if tmp_width <= box.w {
					if params.text_align == .justify {
						tmp_ws := params.word_spacing
						params.word_spacing = pg.calc_word_spacing(tmp_txt, box, params)
						pg.push_content(pg.draw_base_text(tmp_txt, box.x, y, params))
						params.word_spacing = tmp_ws
					} else {
						pg.push_content(pg.draw_base_text(tmp_txt, box.x +
							(box.w - tmp_width) * right_align +
							center_align * (box.w - tmp_width) * 0.5, y, params))
					}
					y += row_height
					if y > (box.y + box.h) {
						if c + 1 == rows.len {
							pg.push_content('0 Tw\n')
							return true, '', y
						}
						// println("Too much text! [CL]")
						leftover_text := words_list[l..].join(' ').trim_space() + '\n' + rows[c +
							1..].join('\n')
						pg.push_content('0 Tw\n')
						return false, leftover_text, y
					}
					words_list = words_list[l..]
					l = words_list.len
					continue
				}
				l--
			}
		}
	}
	// all the text fitted
	pg.push_content('0 Tw\n')
	return true, '', y
}

/******************************************************************************
*
* Draw graphic
*
******************************************************************************/
pub fn (pg Page) draw_rect(b Box) string {
	// box coordinates transformation
	x0 := (b.x * pg.user_unit)
	x1 := x0 + b.w * pg.user_unit
	y0 := pg.media_box.h - b.y * pg.user_unit
	y1 := y0 - b.h * pg.user_unit

	rect_txt := '
$x0 $y0 m
$x1 $y0 l
$x1 $y1 l
$x0 $y1 l
$x0 $y0 l
S
'
	return rect_txt
}

pub fn (pg Page) draw_filled_rect(b Box) string {
	// box coordinates transformation
	x0 := (b.x * pg.user_unit)
	x1 := x0 + b.w * pg.user_unit
	y0 := pg.media_box.h - b.y * pg.user_unit
	y1 := y0 - b.h * pg.user_unit

	rect_txt := '
$x0 $y0 m
$x1 $y0 l
$x1 $y1 l
$x0 $y1 l
$x0 $y0 l
f
S
'
	return rect_txt
}

/******************************************************************************
*
* Pattern: axis Shader
*
******************************************************************************/
/*
2 0 obj
<<
/ProcSet [/PDF /Text /ImageB /ImageC /ImageI]
/Font << /F1 3 0 R /F2 4 0 R >>
/XObject << /XT5 5 0 R /I0 11 0 R >>
/Pattern << /p1 15 0 R /p2 19 0 R /p3 21 0 R /p4 23 0 R /p5 25 0 R >>
/Shading << /Sh1 14 0 R /Sh2 18 0 R /Sh3 20 0 R /Sh4 22 0 R /Sh5 24 0 R >> >>
endobj

// shader axial gradient
12 0 obj
<< /FunctionType 3 /Domain [0 1] /Functions [13 0 R] /Bounds [] /Encode [0 1] >>
endobj
13 0 obj
<< /FunctionType 2 /Domain [0 1] /C0 [1.000000 0.000000 0.000000] /C1 [0.000000 0.000000 0.784314] /N 1 >>
endobj
14 0 obj
<< /ShadingType 2 /ColorSpace /DeviceRGB /Coords [0.000000 0.000000 1.000000 0.000000] /Domain [0 1] /Function 12 0 R /Extend [true true] >>
endobj
15 0 obj
<< /Type /Pattern /PatternType 2 /Shading 14 0 R >>
endobj
*/

pub fn (mut p Pdf) create_linear_gradient_shader(name string, c1 RGB, c2 RGB, angle f32) int {
	// FunctionType 2
	mut f2_obj := Obj{
		id: p.get_new_id()
		is_stream: false
	}
	f2_obj.fields << ' /FunctionType 2 /Domain [0 1] /C0 [$c1.r $c1.g $c1.b] /C1 [$c2.r $c2.g $c2.b] /N 1 '
	p.obj_list << f2_obj

	// FunctionType 3
	mut f3_obj := Obj{
		id: p.get_new_id()
		is_stream: false
	}
	f3_obj.fields << ' /FunctionType 3 /Domain [0 1] /Functions [$f2_obj.id 0 R] /Bounds [] /Encode [0 1] '
	p.obj_list << f3_obj

	// ShadingType 2
	mut s2_obj := Obj{
		id: p.get_new_id()
		is_stream: false
	}
	/*
	s2_obj.fields << " /ShadingType 2 /ColorSpace /DeviceRGB /Coords [0.000000 0.000000 1.000000 0.000000] /Domain [0 1] /Function
	${f3_obj.id} 0 R /Extend [true true] "
	*/

	// rotation angle of the gradient
	grad_sn := math.sin(angle)
	grad_cs := math.cos(angle)
	s2_obj.fields << ' /ShadingType 2 /ColorSpace /DeviceRGB /Coords [0.000000 0.000000 $grad_cs $grad_sn] /Domain [0 1] /Function
	$f3_obj.id 0 R /Extend [true true] '
	p.obj_list << s2_obj

	// shader obj
	mut shader_obj := Obj{
		id: p.get_new_id()
		is_stream: false
	}
	shader_obj.fields << ' /Type /Pattern /PatternType 2 /Shading $s2_obj.id 0 R '
	shader_obj.name = name
	p.obj_list << shader_obj
	return shader_obj.id
}

pub fn (mut pg Page) use_shader(name string) bool {
	index := pg.pdf.get_obj_index_by_name(name)
	if index >= 0 {
		pg.shaders << '/Sh_$name $index 0 R '
		// pg.resources << " /Shading << /Sh_${name} ${index} 0 R >> "
		return true
	}
	return false
}

/*
* q % save state
* ${x} ${y} ${w} ${-h} re % clip Path
* W % clip command
* n % end the path without stroke
* % Modify  the  current  transformation  matrix
* ${grad_len} 0 0 ${grad_len} ${x} ${y} cm
* /Sh_grad sh % Shader name to use for paint
* Q % restore state
*/
pub fn (mut pg Page) draw_gradient_box(name string, b Box, in_grad_len f32) string {
	// box coordinates transformation
	x := (b.x * pg.user_unit)
	w := b.w * pg.user_unit
	y := pg.media_box.h - b.y * pg.user_unit
	h := b.h * pg.user_unit
	grad_len := in_grad_len * pg.user_unit
	return '
q
$x $y $w ${-h} re W n
$grad_len 0 0 $grad_len $x $y cm
/Sh_$name sh
Q
'
}

/******************************************************************************
*
* Utility
*
******************************************************************************/
// utf8util_char_len calculate the length in bytes of a utf8 char
fn utf8util_char_len(b u8) int {
	return ((0xe5000000 >> ((b >> 3) & 0x1e)) & 3) + 1
}

// get_uchar convert a unicode glyph in string[index] into a int unicode char and return the couple (char,len)
fn get_uchar(s string, index int) (int, int) {
	mut res := 0
	mut ch_len := 0
	unsafe {
		if s.len > 0 {
			ch_len = utf8util_char_len(s.str[index])

			if ch_len == 1 {
				return u16(s.str[index]), 1
			}
			if ch_len > 1 && ch_len < 5 {
				mut lword := u16(0)
				for i := 0; i < ch_len; i++ {
					lword = (lword << 8 | s.str[index + i])
				}

				// 2 byte utf-8
				// byte format: 110xxxxx 10xxxxxx
				//
				if ch_len == 2 {
					res = (lword & 0x1f00) >> 2 | (lword & 0x3f)
				}
				// 3 byte utf-8
				// byte format: 1110xxxx 10xxxxxx 10xxxxxx
				//
				else if ch_len == 3 {
					res = (lword & 0x0f0000) >> 4 | (lword & 0x3f00) >> 2 | (lword & 0x3f)
				}
				// 4 byte utf-8
				// byte format: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
				//
				else if ch_len == 4 {
					res = ((lword & 0x07000000) >> 6) | ((lword & 0x003f0000) >> 4) | ((lword & 0x00003F00) >> 2) | (lword & 0x0000003f)
				}
			}
		}
	}
	return res, ch_len
}

// calc_string_bb get a string and a Text_params struct and return his base bounding box (width,y_min,y_max)
pub fn (pg Page) calc_string_bb(txt string, params Text_params) (f32, f32, f32) {
	mut w := f32(0)
	mut w_s := f32(0)
	mut index := 0
	mut space_scale := if params.word_spacing > 0.0 {
		f32(params.word_spacing * pg.user_unit)
	} else {
		f32(0.0)
	}

	mult := (params.font_size) / (1000.0 * pg.user_unit)

	// println("space_scale: ${space_scale}")
	mut width := f32(0)
	mut ascender := f32(0) 
	mut descender := f32(0)
	if params.font_name in pg.pdf.ttf_font_used {
		ft_rsc := pg.pdf.ttf_font_used[params.font_name]
		for {
			ch, len := get_uchar(txt, index)
			w_index := ch-ft_rsc.first_char
			mut w_glyph := 0
			if  w_index >= 0 && w_index < ft_rsc.widths.len {
				// println("Found: ${ch:c} => ${ft_rsc.widths[w_index]}")
				w_glyph = ft_rsc.widths[w_index]
			} else {
				// println("Not found: ${ch:c}")
			}
			w += w_glyph
			// manage space_scale for the space char
			if len == 1 && ch == 0x20 {
				w_s += space_scale
			}
			index += len
			if index > txt.len {
				break
			}
		}

		ascender = f32(ft_rsc.ascent) * mult
		descender = f32(ft_rsc.descent) * mult
	} else {
		for {
			ch, len := get_uchar(txt, index)
			glyph := pg.pdf.u_to_glyph_table[ch.str()]
			w_glyph := base_font_metrics[params.font_name][glyph]
			// println("$ch $len $glyph [$w_glyph]")
			w += w_glyph
			// manage space_scale for the space char
			if len == 1 && ch == 0x20 {
				w_s += space_scale
			}
			index += len
			if index > txt.len {
				break
			}
		}
		ascender = f32(base_font_params[params.font_name]['Ascender']) * mult
		descender = f32(base_font_params[params.font_name]['Descender']) * mult
	}
	
	width = f32(w) * mult + (w_s / pg.user_unit)

	
	
	return width, ascender, descender
}

//
// state save and restore
//
pub fn (mut pg Page) push_state() string {
	return 'q\n'
}

pub fn (mut pg Page) pop_state() string {
	return 'Q\n'
}

/******************************************************************************
*
* Main
*
******************************************************************************/
/*
fn main1(){
	txt := "BT /F1 14 Tf 10 10 Td (Hello World2) Tj ET"
	cmp_len := C.compressBound(txt.len)
	println("txt.len: ${txt.len} cmp_len:${cmp_len}")
	mut buf := malloc(int(cmp_len))

	cmp_status := C.compress(buf, &cmp_len, charptr(txt.str), u32(txt.len))
	println(cmp_status)
	if cmp_status != C.MZ_OK {
		println("Failed!")
		free(buf)
	}

	mut res := strings.new_builder(2048)
	res.write("<</Length ${cmp_len} /Filter/FlateDecode>> >>\nstream\n")
	res.write_bytes(buf,int(cmp_len))
	res.write("\nendstream")
	println(res.str())

}
*/
