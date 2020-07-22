# vPDF

## Introduction

From wikipedia:

*The Portable Document Format (PDF) is a file format developed by Adobe in the 1990s to present documents, including text formatting and images, in a manner independent of application software, hardware, and operating systems. Based on the PostScript language, each PDF file encapsulates a complete description of a fixed-layout flat document, including the text, fonts, vector graphics, raster images and other information needed to display it. PDF was standardized as ISO 32000 in 2008, and no longer requires any royalties for its implementation.*

PDF is a commonly used file format, but producing a PDF file is not a simple task.

This module was created to simplify PDF file creation using the [V programming langauge](https://vlang.io/).

**vPDF** is structured in two layers, low and high.

### Low level layer

At the lower level, it is possible to create a PDF and write directly to it.  This layer is intended for users that are familiar with the PDF format, and wish to create files with as little overhead as possible.  You will, however, have to keep track of all the details yourself.

### High level layer

At the higher level, there are various functions which simplify creating a PDF, and no knowledge of the PDF format is required to use them.

## QuickStart

Let's start with a reasonably simple example: creating a PDF with only one page and with a simple string on it. For this example we will use the high level layer of **vPDF**:

### Complete source (example 06)

```v
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
}
```

Now we'll break down the code:

### PDF creation

First we need to create a PDF and initialize the necessary structures:

```v
mut doc := pdf.Pdf{}
doc.init()
```

### Page format and creation

Once we have the PDF structure, we need to create the page or pages. The page can have several parameters such as: dimensions, a flag that indicates if we want **vPDF** to automatically create the objects or we want do it manually, etc.

For this example we use the simplest configuration possible.  We want to create an `A4` page (210x297 mm), we want **vPDF** to handle object creation and tracking for us, and we do not want to compress the output:

```v
page_n := doc.create_page({
	format: 'A4',
	gen_content_obj: true,
	compress: false
})
```

When the page is created, the `create_page` routine returns the index of the page in the **vPDF** page array.

To modify the page, we need to set millimeters as the working unit size for the page:

```v
mut page := &doc.page_list[page_n] // get the page struct
page.user_unit = pdf.mm_unit       // set millimeters for all operations
```

### Font selection and use

To write a simple string we need to tell the page which font we want to use, and its properties.

First we create a `Text_params` *struct* that contains all the information **vPDF** needs to instantiate and use a font:

We want a 22pt Helvetica font, and we set the font (stroke) color and fill color:

```v
mut fnt_params := pdf.Text_params{
	font_size    : 22.0
	font_name    : "Helvetica"
	s_color : {r:0,g:0,b:0}
	f_color : {r:0,g:0,b:0}
}
```

At present, **vPDF** only supports Type1 fonts. The fonts available in this module are: `['Courier-Bold', 'Courier-BoldOblique', 'Courier-Oblique', 'Courier', 'Helvetica-Bold', 'Helvetica-BoldOblique', 'Helvetica-Oblique', 'Helvetica', 'Symbol', 'Times-Bold', 'Times-BoldItalic', 'Times-Italic', 'Times-Roman', 'ZapfDingbats']`

Then tell **vPDF** the font we want use in the PDF file:

```v
doc.use_base_font(fnt_params.font_name)
```

### Write a string

A PDF page is written in FIFO order, like a queue. Using the high level layer we don't need to care about creation of the objects or their indexing.

To write a string at 10 mm from the left border and 10 mm from the top border of the page we only need to do:

```v
page.push_content(
	page.draw_base_text("My first string.", 10, 10, fnt_params)
)
```

### Render the PDF

At this point our example PDF is complete, so tell **vPDF** to render the result.  The rendering function returns a `strings.Builder`:

```v
txt := doc.render()
```

### Save the file

With the returned `strings.builder`, we can do whatever we want - save the PDF to disk, return it as a HTTP response, or whatever else is needed.

In this quickstart we will write the PDF file to disk:

```v
os.write_file_array('example06.pdf', txt.buf)
```

## Resulting PDF

Since we chose not to compress the PDF, it can be opened in a simple text editor so we can read its raw form  Note that you would normally open the file with a PDF reader - this is for illustrative purposes only.  The contents of the PDF file as written by this example should be:

```
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages  2 0 R  >>
endobj

2 0 obj
<< /Type /Pages  /Kids[ 3 0 R  ]  /Count 1  >>
endobj

3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox  [ 0 0 595.274 841.888 ] /CropBox   [ 0 0 595.274 841.888 ] /Resources  <<  /ProcSet  [/PDF/ImageB/ImageC/ImageI/Text]  /Font  <<  /F0  5 0 R  >>  >>  /Contents  4 0 R  >>
endobj

4 0 obj
<< /Length 77 >>
stream

BT
/F0 22 Tf
0 0 0 RG 0 0 0 rg
28.3464 813.542 Td
(My first string.) Tj
ET

endstream
endobj

5 0 obj
<< /Name /F0 /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /MacRomanEncoding  >>
endobj

xref
0 1
0000000000 65535 f
1 1
0000000009 00000 n
2 1
0000000061 00000 n
3 1
0000000124 00000 n
4 1
0000000351 00000 n
5 1
0000000479 00000 n
trailer
<</Size 6/Root 1 0 R>>
startxref
589
%%EOF
```

## Add a JPEG image

Now we can add an image to the page, it can be simply done adding the following lines just before the rendering operation:

```v
// read a jpeg image from the disk
jpeg_data := os.read_bytes("data/v.jpg") or { panic(err) }
jpeg_id := doc.add_jpeg_resource(jpeg_data)
// tell the page we want use a this jpeg in the page
page.use_jpeg(jpeg_id)

// get width and height in pixel of the jpeg image
_, w, h := pdf.get_jpeg_info(jpeg_data)
h_scale := h / w

page.push_content(
page.draw_jpeg(jpeg_id, {x:10, y:60, w:30, h:30 * h_scale})
)
```

First we need to load in memory the image, this task is achieved with: `os.read_bytes("data/v.jpg")`

Now we must add the jpeg to the resources of the PDF: `doc.add_jpeg_resource(jpeg_data)` that return an id that we will use to identify the jpeg as PDF resource.

**Note:** *All the resources of a PDF file like images, fonts etc must be loaded and stored inside the PDF itself as PDF objects.*

The  **vPDF** module take care about the creation of the objects and their indexing.

Now we must use the jpeg, this usage belong to the page and we must tell to the page that we want use a specific image, we do this with: `page.use_jpeg(jpeg_id)`

Before draw the image we can collect some info on it using: `_, w, h := pdf.get_jpeg_info(jpeg_data)` in this case we need only the width and the height of the jpeg.

Now we can draw our jpeg in the pdf using:

```v
page.push_content(
	page.draw_jpeg(jpeg_id, {x:10, y:60, w:30, h:30 * h_scale})
)
```

where we specify the `jpeg_id` returned by the `add_jpeg_resource` call and a `Box` with the position and dimension where we want the jpeg.

In this case we will draw the jpeg at 10 mm from the left border and 60 mm from the top border with a width of 30mm and a height proportional to the source.

### Complete source (example 07)

```v
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

	// read a jpeg image from the disk
	jpeg_data := os.read_bytes("data/v.jpg") or { panic(err) }
	jpeg_id := doc.add_jpeg_resource(jpeg_data)
	// tell the page we want use a this jpeg in the page
	page.use_jpeg(jpeg_id)

	// get width and height in pixel of the jpeg image
	_, w, h := pdf.get_jpeg_info(jpeg_data)
	h_scale := h / w
	
	page.push_content(
		page.draw_jpeg(jpeg_id, {x:10, y:60, w:30, h:30 * h_scale})
	)

	// render the PDF
	txt := doc.render()

	// write it to a file
	os.write_file_array('example07.pdf', txt.buf)
}
```

