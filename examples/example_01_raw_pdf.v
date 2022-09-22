import pdf
import os

fn main() {
	mut doc := pdf.Pdf{}
	doc.init()

	page_n := doc.create_page(pdf.Page_params{})
	mut page := &doc.page_list[page_n]

	// add default PDF Courier font, no need to include it
	mut font_obj := pdf.Obj{
		id: doc.get_new_id()
	}
	font_name := 'Helvetica'
	font_obj.fields << '/Name /F1 /Type /Font /Subtype /Type1 /BaseFont /Courier /Encoding /MacRomanEncoding'
	doc.obj_list << font_obj
	page.resources << '/Font  <<  /F1  $font_obj.id 0 R  >>'

	// add a jpeg to the pdf resources
	jpeg_data := os.read_bytes('data/v.jpg') or { panic(err) }
	jpeg_id := doc.add_jpeg_resource(jpeg_data)

	// use the jpeg in our page
	page.use_jpeg(jpeg_id)

	// create the page Content
	mut content := pdf.Obj{
		id: doc.get_new_id()
		is_stream: true
		compress: true
	}

	// Our first string
	sent := 'Octal codepoints for font: ${font_name}'
	mut v_space := 24

	content.txt = '
        % our jpeg :)
        q
        128 0 0 128 0 200 cm
        /Image$jpeg_id Do
        Q

        % our first string printed in ${font_name} 24
        q
        BT
        /F1 24 Tf
        10 ${710 - v_space * 0} Td
        [($sent)] TJ
        ET
        Q
    '

    // Octal direct codepoint use, it depends on the font used
    content.txt += 'q'
	mut i:=0
	limit := 0o777
	for i < limit {
		mut txt1 := ""
		start_i := i
		step_len := i + 40
		for i < limit && i < step_len {
			txt1 += "\\${i:03o}"
			i++
		}
		content.txt += '
		BT
        /F1 10 Tf
        10 ${710 - v_space } Td
        [(0o${start_i:03o} => ${txt1})] TJ
        ET
		'
		v_space += 10
	}
	content.txt += 'Q'


	// add the page Object to the PDF
	doc.add_page_obj(mut page, content)

	// render the PDF
	txt := doc.render() ?

	// write it to a file
	os.write_file_array('example01.pdf', txt) ?
}
