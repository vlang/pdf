# vPDF

## Introduction

From wikipedia:

*The Portable Document Format (PDF) is a file format developed by Adobe in the 1990s to present documents, including text formatting and images, in a manner independent of application software, hardware, and operating systems. Based on the PostScript language, each PDF file encapsulates a complete description of a fixed-layout flat document, including the text, fonts, vector graphics, raster images and other information needed to display it. PDF was standardized as ISO 32000 in 2008, and no longer requires any royalties for its implementation.*

PDF is a common used and wide spread file format, but produce a PDF file it is not a simple task.

The purpose of this module is to have a small and simple V module in order to create in a quick way simple PDF files.

**vPDF** is structured in two layer, low and high.

## Module layers

This module is thinked as a minimal PDF creator for a simply use and for produce simple and small PDF.

The module present different layer of usages:

- low level layer
- high level layer

### Low level layer

At low level layer it is possible create PDF and write directly to it using few functions.
This layer is intended for users that are able to manage the low level of the PDF files.

### High level layer

At high level there are various functions with the purpose to simplify the writing of the contents of the PDF, no knowledge of the PDF format is required to use them.

## QuickStart

Let's start with the simplest code possible with this module: the creation of a PDF with only one page and with a simple string on it. For this scope we will use the high level layer of **vPDF** :

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

Let's breakdown the code:

#### PDF creation

First of all we need to create a PDF and initialize all the thing the we need to use in it:

```v
mut doc := pdf.Pdf{}
doc.init()
```

#### Page format and creation

When we have our PDF we need to create the page or the pages. The page can have a lot of parameters like: dimensions, flag that indicate if we want the **vPDF** do automatically the objects creation or we want do it manually etc. 

For this example we use the simplest configuration possible:

-  `format:` we will create an ISO A4 page (210 x 297 mm), we will tell to **vPDF** that for the operations in the page we will use millimeters.
- `gen_content_obj:` we want the **vPDF** willcare abiut the creation of the page objects. 
- `compress:` we don't want that the objects will be compressed by default. 

```v
page_n := doc.create_page({
	format: 'A4', 
	gen_content_obj: true, 
	compress: false
})
```

after that the page is created and the `create_page` return the index of the page in the page array in the **vPDF** page list.

To operate on the page we need to get it and set our millimeters as working unit for the page:

```v
mut page := &doc.page_list[page_n] // get the page struct
page.user_unit = pdf.mm_unit       // set to use millimeters for the operations
```

#### Font selection and use

Before we can write a simple string we need to communicate to the page what font we want use and its properties.

First we create a `Text_params` *struct* that contain all the information **vPDF** need to instantiate and use a font:

```v
mut fnt_params := pdf.Text_params{
	font_size    : 22.0
	font_name    : "Helvetica"
	s_color : {r:0,g:0,b:0}
	f_color : {r:0,g:0,b:0}
}
```

- `font_size:` we using a 22 point dimension for our font
- `font_name:` at the present time only the PDF's default font of Type1 are available in the module, the list of the font name is: `['Courier-Bold', 'Courier-BoldOblique', 'Courier-Oblique', 'Courier', 'Helvetica-Bold', 'Helvetica-BoldOblique', 'Helvetica-Oblique', 'Helvetica', 'Symbol', 'Times-Bold', 'Times-BoldItalic', 'Times-Italic', 'Times-Roman', 'ZapfDingbats']`
- `s_color:` is the color for the stroke operations
- `f_color:`is the color for the fill operations

After that we can tell to **vPDF** the font we want use in the PDF file :

```v
doc.use_base_font(fnt_params.font_name)
```

#### Write a string

A PDF page is written with a FIFO policy, like a queue. Using the high level layer we don't need to care about the creation of the objects or their indexing.

To write a string at 10 millimeters from the left border and 10 millimeters from the top border of the page we need only to write:

```v
page.push_content( 
	page.draw_base_text("My first string.", 10, 10, fnt_params)
)
```

#### Render the PDF

At this point we have all we need e we can tell to **vPDF** to render the PDF using, the rendering function return a  `strings.Builder`:

```v
txt := doc.render()
```

#### Save the file

With the result as s string builder we can do what we want, save on disk, return it like a HTTP response are whatever.

In this quickstart we will save the PDF file on the storage:

```v
os.write_file_array('example06.pdf', txt.buf)
```

## Result PDF

the obtained PDF file can be open in a simple text editor, and because we chosen to do not compress it we can read its raw form:

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



 



