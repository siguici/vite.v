module vite

import os
import json
import veb

@[params]
struct ViteConfig {
	manifest_file string = 'manifest.json'
	hot_file      string = 'hot'
	public_dir    string = 'public'
	build_dir     string = 'build'
}

@[params]
struct AssetOptions {
	is_dev    bool
	use_react bool
}

struct Vite {
mut:
	manifest_file   string @[required]
	hot_file        string @[required]
	public_dir      string @[required]
	build_dir       string @[required]
	app_url         string = 'http://localhost:5173'
	is_dev          bool
	manifest        ViteManifest
	manifest_loaded bool
}

struct ViteAsset {
	file             string @[required]
	name             string
	src              string
	is_entry         bool
	is_dynamic_entry bool
	css              []string
	imports          []string
	dynamic_imports  []string
}

type ViteManifest = map[string]ViteAsset

pub fn Vite.new(config ViteConfig) Vite {
	mut v := Vite{
		manifest_file: config.manifest_file
		hot_file:      config.hot_file
		public_dir:    config.public_dir
		build_dir:     config.build_dir
	}

	return v.init()
}

pub fn new_v(config ViteConfig) Vite {
	return Vite.new(config)
}

pub fn (v Vite) manifest_path() string {
	return '${v.public_dir}/${v.build_dir}/${v.manifest_file}'
}

pub fn (v Vite) hot_path() string {
	return '${v.public_dir}/${v.hot_file}'
}

pub fn (mut v Vite) assets(names []string, options AssetOptions) veb.RawHtml {
	mut render := ''

	if options.is_dev || v.is_dev {
		render = v.dev_scripts(options)
	}

	for name in names {
		render = '${render}${v.asset(name)}'
	}
	return render
}

pub fn (mut v Vite) asset(name string) veb.RawHtml {
	asset := v.chunk(name)
	file := asset.file

	if file == '' {
		panic('Unable to locate ${name} in Vite manifest.')
	}

	css := asset.css
	imports := asset.imports

	mut html := ''
	mut base := ''
	mut path := ''

	if v.is_dev {
		base = '${v.app_url}/'
		path = name
	} else {
		base = '${v.app_url}/${v.build_dir}/'
		path = file
	}

	for css_file in css {
		html += v.style(base + css_file)
	}

	for chunk in imports {
		html += if v.is_css(chunk) {
			v.style(base + chunk)
		} else {
			v.preload(base + chunk)
		}
	}

	html += if v.is_css(path) {
		v.style(base + path)
	} else {
		v.defer_script(base + path, '')
	}

	return html
}

pub fn (mut v Vite) chunk(name string) ViteAsset {
	manifest := v.manifest()

	return manifest[name]
}

fn (v Vite) is_css(path string) bool {
	return match os.file_ext(path) {
		'.css', '.less', '.sass', '.scss', '.styl', '.stylus', '.pcss', '.postcss' {
			true
		}
		else {
			false
		}
	}
}

pub fn (v Vite) dev_scripts(options AssetOptions) veb.RawHtml {
	mut render := v.script('${v.app_url}/@v/client', '')

	if options.use_react {
		render = '${render}${v.react_script()}'
	}

	return render
}

pub fn (v Vite) react_script() veb.RawHtml {
	mut content := ''
	content += 'import RefreshRuntime from "${v.app_url}/@react-refresh";'
	content += 'RefreshRuntime.injectIntoGlobalHook(window);'
	content += 'window.\$RefreshReg\$ = () => {};'
	content += 'window.\$RefreshSig\$ = () => (type) => type;'
	content += 'window.__v_plugin_react_preamble_installed__ = true;'
	return v.script('', content)
}

pub fn (v Vite) style(href string) string {
	attrs := [
		new_attribute('rel', 'stylesheet'),
		new_attribute('href', href),
	]
	return new_style(attrs, '').str()
}

pub fn (v Vite) preload(href string) string {
	attrs := [
		new_attribute('rel', 'modulepreload'),
		new_attribute('href', href),
	]
	return new_tag('link', attrs, '').str()
}

pub fn (v Vite) script(src string, content TagContent) string {
	mut attrs := [
		new_attribute('type', 'module'),
	]

	if src != '' {
		attrs << new_attribute('src', src)
	}

	return new_script(attrs, content).str()
}

pub fn (v Vite) defer_script(src string, content TagContent) string {
	attrs := [
		new_attribute('src', src),
		new_attribute('type', 'module'),
		new_attribute('defer', true),
	]

	return new_script(attrs, content).str()
}

pub fn (mut v Vite) init() Vite {
	hot_path := v.hot_path()

	if os.is_file(hot_path) {
		v.is_dev = true
		v.app_url = os.read_file(hot_path) or { panic(err) }
	} else {
		v.is_dev = false
		v.app_url = os.getenv('APP_URL')
	}

	return v
}

pub fn (mut v Vite) manifest() ViteManifest {
	if !v.manifest_loaded {
		manifest_path := v.manifest_path()

		if !os.is_file(manifest_path) {
			panic('Vite manifest ${manifest_path} not found.')
		}

		v.manifest = json.decode(ViteManifest, os.read_file(manifest_path) or { panic(err) }) or {
			panic(err)
		}

		v.manifest_loaded = true
	}

	return v.manifest
}
