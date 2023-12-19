import pdf
import os

fn main() {
	mut doc := pdf.Pdf{}
	doc.init()

	// add TTF font obj
	font_name := 'GR'
	doc.load_ttf_font('data/Graduate-Regular.ttf', font_name, 1.0)

	page_n := doc.create_page(pdf.Page_params{
		format: 'A4'
		gen_content_obj: true
		compress: false
	})
	mut page := &doc.page_list[page_n]
	page.user_unit = pdf.mm_unit

	mut fnt_params := pdf.Text_params{
		font_size: 22.0
		font_name: font_name
		s_color: pdf.RGB{
			r: 0
			g: 0
			b: 0
		}
		f_color: pdf.RGB{
			r: 0
			g: 0
			b: 0
		}
	}

	// Declare the base (Type1 font) we want use
	if fnt_params.font_name != font_name && !doc.use_base_font(fnt_params.font_name) {
		eprintln('ERROR: Font ${fnt_params.font_name} not available!')
		return
	}

	// write the string plus € symbol using an octal codepoint
	// for the font Graduate-Regular.ttf in the data folder
	// that use the ISO-8859-1 Latin1 codification of chars
	// € is 0x80 or 0o200 or 128 in decimal.
	// In PDF you can indicate the codepoint in octal code using the `\`
	// backslash before the octal value of the char
	page.push_content(page.draw_base_text('Test string. Euro symbol: \200', 10, 10, fnt_params))

	// write €ABC using hex value of the chars, 3-byte UTF-8 BOM
	page.push_content(page.draw_raw_text('<80 41 42 43>', 10, 32, fnt_params))

	// write the string as unicode bytes in the pdf
	e := 'ciao \200'
	page.push_content(page.draw_unicode_text(e, 10, 52, fnt_params))

	// render the PDF
	txt := doc.render()!

	// write it to a file
	os.write_file_array('example09.pdf', txt)!
}
