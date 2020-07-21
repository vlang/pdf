import pdf
import os

fn main(){
	mut doc := pdf.Pdf{}
	doc.init()

	page_n := doc.create_page({
		format: 'A4', 
		gen_content_obj: true, 
		compress: false
	})
	mut page := &doc.page_list[page_n]
	page.user_unit = pdf.mm_unit //1.0 // set 1/72 of inch

	mut fnt_params := pdf.Text_params{
		font_size    : 22.0
		font_name    : "Helvetica"
		s_color : {r:0,g:0,b:0}
		f_color : {r:0,g:0,b:0}
	}

	// Declare the base (Type1 font) we want use
	if !doc.use_base_font(fnt_params.font_name) {
		eprintln("ERROR: Font ${fnt_params.font_name} not available!")
		return
	}

	// write the string
	page.push_content( 
		page.draw_base_text("My first string.", 10, 10, fnt_params)
	)

	// render the PDF
	txt := doc.render()

	// write it to a file
	os.write_file_array('example06.pdf', txt.buf)

	println(pdf.get_base_font_list())
}