import pdf
import os
import math

fn main() {
	mut doc := Pdf{}
	doc.init()

	page_n := doc.create_page(Page_params{})
	// println("page index $page_n")
	mut page := &doc.page_list[page_n]
	page.set_unit('mm')

	// add font
	mut font_obj := Obj{
		id: doc.get_new_id()
	}
	font_obj.fields << '/Name /F1 /Type /Font /Subtype /Type1 /BaseFont /Courier /Encoding /MacRomanEncoding'
	doc.obj_list << font_obj
	page.resources << '/Font  <<  /F1  $font_obj.id 0 R  >>'

	jpeg_data := os.read_bytes('data/v.jpg') or { panic(err) }
	jpeg_id := doc.add_jpeg_resource(jpeg_data)
	page.use_jpeg(jpeg_id)

	// Content
	mut b := Obj{
		id: doc.get_new_id()
		is_stream: true
		compress: true
	}

	sent := 'This is the first V working PDF!'
	v_space := 24

	b.txt = '
q
128 0 0 128 0 200 cm
/Image$jpeg_id Do
Q

q
BT
/F1 24 Tf
10 ${710 - v_space * 0} Td
($sent) Tj
ET

BT
10 ${710 - v_space * 1} Td
0 Tr
0.5 g
($sent) Tj
ET

BT
10 ${710 - v_space * 2} Td
1 Tr
0.3 w
($sent) Tj
ET

BT
10 ${710 - v_space * 3} Td
1 Tr
0.2 w
0.5 g
($sent) Tj
ET
Q

BT
/F1 20 Tf
10 ${710 - v_space * 4} Td
(This ) Tj
-10 Ts
(text ) Tj
10 Ts
(moves ) Tj
0 Ts
(around) Tj
ET

'
	// add circle of text
	n := 32
	for ang in 1 .. n {
		a := ((math.pi * 2.0) / f64(n + 1)) * f64(ang)
		c := (1.0 / f64(n + 1)) * f64(ang)
		cos_v := math.cos(a)
		sin_v := math.sin(a)
		b.txt += '
BT
/F1 8 Tf
0 Tr
$c 0 0 RG
$c 0 0 rg
$cos_v ${-sin_v} $sin_v $cos_v 306 300 Tm
($sent) Tj
ET
'
	}

	b.parts << 'BT 10 100 Td (Ciao da me Dario!)Tj ET'

	doc.add_page_obj(mut page, b)

	// page 2
	page_2 := doc.create_page(Page_params{})
	page = &doc.page_list[page_2]
	// font used
	page.resources << '/Font  <<  /F1  $font_obj.id 0 R  >>'

	// add jepg to the page
	page.use_jpeg(jpeg_id)

	// Content
	mut b1 := Obj{
		id: doc.get_new_id()
		is_stream: true
		compress: false
	}
	str1 := ' Second page!'
	b1.txt = 'BT /F1 20 Tf 10 700 Td ($str1)Tj ET\n'
	b1.parts << 'BT /F1 20 Tf 10 600 Td (${str1}2!)Tj ET\n'
	b1.parts << 'BT /F1 20 Tf 10 550 Td (${str1}3!)Tj ET\n'

	a := (math.pi / 180.0) * 30.0
	cos_v := math.cos(a)
	sin_v := math.sin(a)
	sz := 128.0
	b1.parts << 'q ${sz * cos_v} ${-sin_v * sz} ${sin_v * sz} ${cos_v * sz} 0 200 cm /Image$jpeg_id Do Q '
	// b1.parts << "q 128 0 0 128 0 200 cm /Image$jpeg_id Do Q"

	doc.add_page_obj(mut page, b1)

	txt := doc.render()?

	// write it to a file
	os.write_file_array('example02.pdf', txt)?
}
