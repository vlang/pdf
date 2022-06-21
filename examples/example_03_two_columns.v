import pdf
import os

fn main() {
	mut doc := Pdf{}
	doc.init()

	page_n := doc.create_page(Page_params{
		format: 'A4'
		gen_content_obj: true
		compress: true
	})
	mut page := &doc.page_list[page_n]
	page.user_unit = mm_unit

	mut fnt_params := Text_params{
		font_size: 22.0
		font_name: 'Helvetica'
		render_mode: -1
		word_spacing: -1
		s_color: RGB{
			r: 0
			g: 0
			b: 0
		}
		f_color: RGB{
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

	//----- test box text -----
	fnt_params.word_spacing = 0
	fnt_params.font_size = 12

	mut my_str := "Quicksort (sometimes called partition-exchange sort) is an efficient sorting algorithm.
	Developed by British computer scientist Tony Hoare in 1959 and published in 1961, it is still a commonly used algorithm for sorting. When implemented well, it can be about two or three times faster than its main competitors, merge sort and heapsort.
	Quicksort is a divide-and-conquer algorithm. It works by selecting a 'pivot' element from the array and partitioning the other elements into two sub-arrays, according to whether they are less than or greater than the pivot. The sub-arrays are then sorted recursively. This can be done in-place, requiring small additional amounts of memory to perform the sorting.
	Quicksort is a comparison sort, meaning that it can sort items of any type for which a 'less-than' relation (formally, a total order) is defined. Efficient implementations of Quicksort are not a stable sort, meaning that the relative order of equal sort items is not preserved.
	Mathematical analysis of quicksort shows that, on average, the algorithm takes O[n log n] comparisons to sort n items. In the worst case, it makes O[n2] comparisons, though this behavior is rare.
	Best solutions can be available!
	Soon or later they will be available."

	my_str = my_str + my_str
	my_str = my_str + my_str

	//----- Text Area -----
	tb := Box{
		x: page.media_box.x / page.user_unit + 10
		y: 20
		w: page.media_box.w / page.user_unit - 20
		h: page.media_box.h / page.user_unit - 20
	}

	// justify align
	fnt_params.text_align = .justify
	mut tmp_txt := my_str
	mut tmp_res := false
	mut lo_txt := ' '

	// set two columns
	boxes := [
		Box{
			x: tb.x
			y: tb.y
			w: tb.w / 2 - 10
			h: tb.h - 20
		},
		Box{
			x: tb.x + tb.w / 2 + 5
			y: tb.y
			w: tb.w / 2 - 10
			h: tb.h - 20
		},
	]

	for bx in boxes {
		if lo_txt.len > 0 {
			tmp_res, lo_txt, _ = page.text_box(tmp_txt, bx, fnt_params)
			if tmp_res {
				break
			}
			tmp_txt = lo_txt
			// println("leftover: [${lo_txt}]")
		}
	}
	// println("res: ${tmp_res} left_over: [${lo_txt}]")

	// render the PDF
	txt := doc.render()?

	// write it to a file
	os.write_file_array('example03.pdf', txt)?
}
