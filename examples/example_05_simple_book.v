import pdf
import os

const (
	file_name       = 'alice_in_wonderland'

	page_iso_format = 'A4'
	pg_fmt          = pdf.page_fmt[page_iso_format]
	text_box        = pdf.Box{
		x: pg_fmt.x + 30
		y: 20
		w: pg_fmt.w - 60
		h: pg_fmt.h - 40
	}
)

fn main() {
	mut src_txt := os.read_file('data/${file_name}.txt') or { panic(err) }

	mut doc := pdf.Pdf{}
	doc.init()

	mut fnt_params := pdf.Text_params{
		font_size: 12
		font_name: 'Helvetica'
		text_align: .left
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
	if !doc.use_base_font(fnt_params.font_name) {
		eprintln('ERROR: Font $fnt_params.font_name not available!')
		return
	}

	mut tmp_res := false
	mut lo_txt := ' '

	// render the pages
	for src_txt.len > 0 {
		page_n := doc.create_page(pdf.Page_params{
			format: page_iso_format
			gen_content_obj: true
			compress: true
		})
		mut page := &doc.page_list[page_n]
		page.user_unit = pdf.mm_unit
		//----- Page text -----
		tmp_res, lo_txt, _ = page.text_box(src_txt, text_box, fnt_params)
		src_txt = lo_txt
	}
	// render the headers and footers
	mut index := 0
	for index < doc.page_list.len {
		mut page := &doc.page_list[index]
		//----- Header -----
		fnt_params.font_size = 8.0
		header := '$file_name'
		fnt_params.text_align = .center
		page.text_box(header, pdf.Box{
			x: 10
			y: 12
			w: pg_fmt.w - 20
			h: 20
		}, fnt_params)

		//----- Footer -----
		fnt_params.font_size = 8.0
		footer := 'Page ${index + 1} of $doc.page_list.len'
		fnt_params.text_align = .right
		page.text_box(footer, pdf.Box{
			x: 10
			y: pg_fmt.h - 10
			w: pg_fmt.w - 30
			h: 20
		}, fnt_params)

		index++
	}

	// render the PDF
	txt := doc.render()!

	// write it to a file
	os.write_file_array('example05.pdf', txt)!
}
