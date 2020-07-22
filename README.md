# vPDF

## Introduction

From wikipedia:

*The Portable Document Format (PDF) is a file format developed by Adobe in the 1990s to present documents, including text formatting and images, in a manner independent of application software, hardware, and operating systems. Based on the PostScript language, each PDF file encapsulates a complete description of a fixed-layout flat document, including the text, fonts, vector graphics, raster images and other information needed to display it. PDF was standardized as ISO 32000 in 2008 and no longer requires any royalties for its implementation.*

PDF is a commonly-used and widespread file format, but producing one is not a simple task.

The purpose of this module is to have a small V module in order to create PDF files in a quick and simple way.

## Module layers

>This module should be thought of as a minimal PDF creator for use in the production of simple, small PDFs. 

To facilitate this; **vPDF** is structured in two abstraction layers:

### Low level layer
> At low level layer, it is possible create PDF and write directly to it using more of the native attributes of the PDF format.

This layer is intended for users that are able to manage the low level details of PDFs and should be used by those that need more direct control of the generated PDF.

### High level layer
> At high level layer, various features and functions are abstracted away to be managed by the module.
> 
At this layer, the goal is allow anyone to create and generate PDFs with little, to no, knowledge of the underlying format.

## QuickStart

Let's start with the simplest code possible with this module: the creation of a PDF with only one page and with a simple string on it. 

For this demonstration, we will use the high level layer of **vPDF** :

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

First of all, we need to create a PDF and initialize all the things that we will need to start writing to it:

```v
mut doc := pdf.Pdf{}
doc.init()
```

#### Page format and creation

Once we have our PDF initialized, we need to create the page or the pages. The page can have a lot of parameters like: dimensions, flag to indicate if we want the **vPDF** do automatically the objects creation or we want do it manually, etc. 

For this example, we've used the simplest configuration possible:

-  `format:` create an ISO A4 page (210 x 297 mm)
  	* Note: <small>we will have to tell **vPDF** to use millimeters for operations on the page later on</small>
- `gen_content_obj:` tells **vPDF** to handle  the creation of the page objects. 
- `compress:` signals **vPDF** not to compress objects by default. 

```v
page_n := doc.create_page({
	format: 'A4', 
	gen_content_obj: true, 
	compress: false
})
```

After the `create_page` function is called, it returns the index of the page in **vPDF**'s internal page list.
<!--after that the page is created and the `create_page` return the index of the page in the page array in the **vPDF** page list.-->

In the previous snippet, we set the page's format to A4. We'll find using millimeters easier to work with, so let's get the one of interest and set the working units accordingly:
```v
mut page := &doc.page_list[page_n] // get the page struct
page.user_unit = pdf.mm_unit       // set to use millimeters for the operations
```

#### Font selection and use

Before we can write a simple string, we need to communicate to the page what font we want to use and its properties.

First, we create a `Text_params` *struct* that contain all the information **vPDF** need to instantiate and use a font:

```v
mut fnt_params := pdf.Text_params{
	font_size    : 22.0
	font_name    : "Helvetica"
	s_color : {r:0,g:0,b:0}
	f_color : {r:0,g:0,b:0}
}
```

- `font_size:` we are using a 22 point dimension for our font
- `font_name:` at the present; only the PDF's default fonts of the Type1 format are available in the module
  -  Available Type1 fonts are: `['Courier-Bold', 'Courier-BoldOblique', 'Courier-Oblique', 'Courier', 'Helvetica-Bold', 'Helvetica-BoldOblique', 'Helvetica-Oblique', 'Helvetica', 'Symbol', 'Times-Bold', 'Times-BoldItalic', 'Times-Italic', 'Times-Roman', 'ZapfDingbats']`
- `s_color:` is the color for the stroke operations
- `f_color:`is the color for the fill operations

After that, we can tell **vPDF** the font that we want to use in the PDF file :

```v
doc.use_base_font(fnt_params.font_name)
```

#### Write a string

A PDF page is written with a FIFO policy, like a queue. Using the high level layer, we don't need to care about the creation of the objects or their indexing.

To write a string at 10 millimeters from the left border and 10 millimeters from the top border of the page we need only to write:

```v
page.push_content( 
	page.draw_base_text("My first string.", 10, 10, fnt_params)
)
```

#### Render the PDF

At this point, we have all we need to have **vPDF** generate the PDF using its rendering function to return a  `strings.Builder`:

```v
txt := doc.render()
```

#### Save the file

With the result as a string builder we can do what we want, save on disk, return it like a HTTP response, or whatever else we can think of!

In this quickstart, we will save the PDF file on the storage:

```v
os.write_file_array('example06.pdf', txt.buf)
```

## Resultant PDF

The obtained PDF file can be opened in a simple text editor Because we chose not to compress as we went along; we can read the PDF's raw form:

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



 



