import pdf
import os

fn main() {
	mut doc := Pdf{}
	doc.init()

	page_n := doc.create_page(Page_params{})
	mut page := &doc.page_list[page_n]

	// add default PDF Courier font, no need to include it
	mut font_obj := Obj{
		id: doc.get_new_id()
	}
	font_obj.fields << '/Name /F1 /Type /Font /Subtype /Type1 /BaseFont /Courier /Encoding /MacRomanEncoding'
	doc.obj_list << font_obj
	page.resources << '/Font  <<  /F1  $font_obj.id 0 R  >>'

	// add a jpeg to the pdf resources
	jpeg_data := os.read_bytes('data/v.jpg') or { panic(err) }
	jpeg_id := doc.add_jpeg_resource(jpeg_data)

	// use the jpeg in our page
	page.use_jpeg(jpeg_id)

	// create the page Content
	mut content := Obj{
		id: doc.get_new_id()
		is_stream: true
		compress: true
	}

	// Our first string
	sent := 'This is the first V PDF!'
	v_space := 24

	content.txt = '
        % our jpeg :)
        q
        128 0 0 128 0 200 cm
        /Image$jpeg_id Do
        Q

        % our first string printed in Courier 24
        q
        BT
        /F1 24 Tf
        10 ${710 - v_space * 0} Td
        ($sent) Tj
        ET
        Q
    '

	// add the page Object to the PDF
	doc.add_page_obj(mut page, content)

	// render the PDF
	txt := doc.render()?

	// write it to a file
	os.write_file_array('example01.pdf', txt)?
}
