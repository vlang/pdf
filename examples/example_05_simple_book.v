import pdf
import os

const(
	file_name = "alice_in_wonderland"
)

fn main(){
	mut src_txt := os.read_file("data/${file_name}.txt") or {panic(err)}

	mut doc := pdf.Pdf{}
	doc.init()

	mut fnt_params := pdf.Text_params{
		font_size    : 12
		font_name    : "Helvetica"
		render_mode  : -1
		word_spacing : -1
		text_align   : .left
		s_color : {r:0,g:0,b:0}
		f_color : {r:0,g:0,b:0}
	}

	// Declare the base (Type1 font) we want use
	if !doc.use_base_font(fnt_params.font_name) {
		eprintln("ERROR: Font ${fnt_params.font_name} not available!")
		return
	}

	mut tmp_res := false
	mut lo_txt  := " "
	mut last_y  := f32(0)

	for src_txt.len > 0 {
		page_n := doc.create_page({format: 'A4', gen_content_obj: true, compress: true})
		mut page := &doc.page_list[page_n]
		page.user_unit = pdf.mm_unit

		//----- Text Area -----
		tb := pdf.Box{
			x: page.media_box.x/page.user_unit + 30
			y: 20
			w: page.media_box.w/page.user_unit - 60
			h: page.media_box.h/page.user_unit - 40
		}
		
		//----- test box text -----
		//fnt_params.text_align = .left

		tmp_res, lo_txt, last_y  = page.text_box(src_txt, tb, fnt_params)
		src_txt = lo_txt
	}

	mut index := 0
	for index < doc.page_list.len {
		mut page := &doc.page_list[index]
	
		//----- Text Area -----
		tb := pdf.Box{
			x: page.media_box.x/page.user_unit + 20
			y: 20
			w: page.media_box.w/page.user_unit - 40
			h: page.media_box.h/page.user_unit - 40
		}

		//----- Header -----
		fnt_params.font_size = 8.0
		header := "${file_name}"
		fnt_params.text_align = .center
		page.text_box(header, {x:10, y:12, w:tb.w ,h: 20}, fnt_params)

		//----- Footer -----
		fnt_params.font_size = 8.0
		footer := "Page ${index+1} of ${doc.page_list.len}"
		fnt_params.text_align = .right
		page.text_box(footer, {x:tb.x, y:page.media_box.h/page.user_unit-10, w:tb.w ,h: 20}, fnt_params)
		
		index++
	}

	// render the PDF
	txt := doc.render()

	// write it to a file
	os.write_file_array('example05.pdf', txt.buf)
}