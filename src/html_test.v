module vite

fn test_attribute() {
	assert new_attribute('href', 'https://example.com').str() == 'href="https://example.com"'
	assert new_attribute('disabled', true).str() == 'disabled'
	assert new_attribute('disabled', false).str() == ''
}

fn test_attributes() {
	assert [
		new_attribute('href', 'https://example.com'),
		new_attribute('disabled', true),
	].str() == ' href="https://example.com" disabled'
}

fn test_tag() {
	assert new_tag('script', [], '').str() == '<script></script>'
	assert new_tag('link', [], '').str() == '<link>'
	assert new_tag('link', [new_attribute('href', 'https://example.com')], '').str() == '<link href="https://example.com">'
	assert new_tag('script', [new_attribute('src', 'https://example.com')], 'Hello World!').str() == '<script src="https://example.com">Hello World!</script>'
}
