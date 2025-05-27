module vite

pub type AttributeValue = string | bool
pub type TagContent = string | []Tag

pub struct Attribute {
	name  string
	value AttributeValue
}

pub struct Tag {
mut:
	name    string @[required]
	attrs   []Attribute
	content TagContent
}

pub fn Attribute.new(name string, value AttributeValue) Attribute {
	return Attribute{name, value}
}

pub fn new_attribute(name string, value AttributeValue) Attribute {
	return Attribute.new(name, value)
}

pub fn Tag.new(name string, attrs []Attribute, content TagContent) Tag {
	return Tag{name, attrs, content}
}

pub fn new_tag(name string, attrs []Attribute, content TagContent) Tag {
	return Tag.new(name, attrs, content)
}

pub fn (attr Attribute) str() string {
	return if attr.value is string {
		'${attr.name}="${attr.value}"'
	} else {
		if attr.value is bool && attr.value {
			'${attr.name}'
		} else {
			''
		}
	}
}

pub fn (attrs []Attribute) str() string {
	mut render := ''
	for attr in attrs {
		render += ' ${attr.str()}'
	}
	return render
}

pub fn (tag Tag) str() string {
	return if tag.name == 'link' || tag.name == 'img' {
		'<${tag.name}${tag.attrs.str()}>'
	} else {
		content := if tag.content is string { tag.content } else { tag.content.str() }
		'<${tag.name}${tag.attrs.str()}>${content}</${tag.name}>'
	}
}

pub fn (tags []Tag) str() string {
	mut render := ''
	for tag in tags {
		render += tag.str()
	}
	return render
}

pub fn (mut tag Tag) add_attrs(attrs []Attribute) Tag {
	for attr in attrs {
		tag.attrs << attr
	}
	return tag
}

pub fn (mut tag Tag) add_attr(name string, value AttributeValue) Tag {
	tag.attrs << new_attribute(name, value)
	return tag
}

pub fn new_style(attrs []Attribute, content TagContent) Tag {
	tag := if content is string && content == '' {
		new_tag('link', attrs, '')
	} else {
		new_tag('style', attrs, content)
	}
	return tag
}

pub fn new_script(attrs []Attribute, content TagContent) Tag {
	return new_tag('script', attrs, content)
}

pub fn new_image(attrs []Attribute) Tag {
	return new_tag('img', attrs, '')
}
