import pdf
import math
import os

fn main(){
	mut doc := pdf.Pdf{}
	doc.init()

	page_n := doc.create_page({format: 'A4', gen_content_obj: true, compress: false})
	mut page := &doc.page_list[page_n]
	page.user_unit = pdf.mm_unit //1.0 // set 1/72 of inch


	mut fnt_params := pdf.Text_params{
		font_size    : 22.0
		font_name    : "Helvetica"
		render_mode  : -1
		word_spacing : -1
		s_color : {r:0,g:0,b:0}
		f_color : {r:0,g:0,b:0}
	}

	// Declare the base (Type1 font) we want use
	if !doc.use_base_font(fnt_params.font_name) {
		eprintln("ERROR: Font ${fnt_params.font_name} not available!")
		return
	}

	//----- Create gradients -----
	// rgb(83,107,138) V blue 1
	// rgb(93,135,191) V blue 2
	angle := 270.0
	doc.create_linear_gradient_shader(
		"vertical_gradient", 
		{r:83/255.0, g:107/255.0, b:138/255.0}, 
		{r:93/255.0, g:135/255.0, b:191/255.0}, 
		f32(angle*math.pi/180.0) 
	)
	page.use_shader("vertical_gradient")

	// draw  vertical gradient
	page.push_content(page.draw_gradient_box(
		"vertical_gradient", 
		{x:10,y:10,w:10,h:page.media_box.h/page.user_unit-30}, 
		page.media_box.h/page.user_unit-20*2
	))

	//----- Create gradient for the separator -----
	doc.create_linear_gradient_shader(
		"sep_grad", 
		{r:83/255.0, g:107/255.0, b:138/255.0}, 
		{r:93/255.0, g:135/255.0, b:191/255.0}, 
		0
	)
	page.use_shader("sep_grad")

	//----- Text Area -----
	tb := pdf.Box{
		x: page.media_box.x/page.user_unit + 30
		y: 20
		w: page.media_box.w/page.user_unit - 40
		h: page.media_box.h/page.user_unit - 20
	}

	//----- Header -----
	fnt_params.font_size = 6.0
	header := "V manual PDF\nBest Header ever!"
	fnt_params.text_align = .left
	mut res1, _ , mut last_y := page.text_box(header, {x:10, y:0, w:tb.w ,h: 20}, fnt_params)

	//----- Footer -----
	fnt_params.font_size = 8.0
	footer := "Page 1 of 1\nBest footer ever!"
	fnt_params.text_align = .right
	res1, _ , last_y = page.text_box(footer, {x:tb.x, y:page.media_box.h/page.user_unit-10, w:tb.w ,h: 20}, fnt_params)

	//----- Title -----
	fnt_params.font_size = 36.0
	mut y_pos := tb.y
	title := "V test page"
	//mut width, mut ascender, mut descender := page.calc_string_bb(title, fnt_params)
	mut width, _, _ := page.calc_string_bb(title, fnt_params)
	page.push_content( page.draw_base_text(title, tb.x + (tb.w / 2) - width / 2, y_pos, fnt_params) )
	y_pos += page.new_line_offset(fnt_params)

	//----- Sub Title -----
	fnt_params.font_size = 22.0
	fnt_params.leading = 0.2
	sub_title := "A first V page with gradients"
	width, _, _ = page.calc_string_bb(sub_title, fnt_params)
	page.push_content( page.draw_base_text(sub_title, tb.x + (tb.w / 2) - width / 2, y_pos, fnt_params) )
	y_pos += page.new_line_offset(fnt_params)


	//----- test Text ------
	mut p_txt :=
"Quicksort (sometimes called partition-exchange sort) is an efficient sorting algorithm.
Developed by British computer scientist Tony Hoare in 1959 and published in 1961, it is still a commonly used algorithm for sorting. When implemented well, it can be about two or three times faster than its main competitors, merge sort and heapsort.
Quicksort is a divide-and-conquer algorithm. It works by selecting a 'pivot' element from the array and partitioning the other elements into two sub-arrays, according to whether they are less than or greater than the pivot. The sub-arrays are then sorted recursively. This can be done in-place, requiring small additional amounts of memory to perform the sorting.
Quicksort is a comparison sort, meaning that it can sort items of any type for which a 'less-than' relation (formally, a total order) is defined. Efficient implementations of Quicksort are not a stable sort, meaning that the relative order of equal sort items is not preserved."

	fnt_params.font_size = 12.0

	//----- justify align -----
	fnt_params.text_align = .justify
	res1, _ , last_y = page.text_box(p_txt, {x:tb.x, y:y_pos, w:tb.w ,h: 70}, fnt_params)
	y_pos = last_y

	//----- Separator ------
	page.push_content(page.draw_gradient_box(
		"sep_grad", 
		{x:tb.x, y:y_pos ,w:tb.w ,h:0.5}, 
		page.media_box.h/page.user_unit-20*2
	))
	y_pos += 6

	//----- right align -----
	fnt_params.text_align = .right
	res1, _ , last_y = page.text_box(p_txt, {x:tb.x, y:y_pos, w:tb.w ,h: 70}, fnt_params)
	y_pos = last_y + 10
	
	//----- left align -----
	fnt_params.text_align = .left
	res1, _ , last_y = page.text_box(p_txt, {x:tb.x, y:y_pos, w:tb.w ,h: 70}, fnt_params)

	// render the PDF
	txt := doc.render()

	// write it to a file
	os.write_file_array('example04.pdf', txt.buf)
}