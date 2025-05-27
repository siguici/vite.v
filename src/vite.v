module vite

import os
import json
import veb
import veb.assets

@[params]
pub struct ViteConfig {
	manifest_file string = 'manifest.json'
	hot_file      string = 'hot'
	public_dir    string = 'public'
	build_dir     string = 'build'
}

@[params]
pub struct AssetOptions {
	use_react bool
}

pub struct Vite {
	assets.AssetManager
mut:
	manifest_file   string @[required]
	hot_file        string @[required]
	public_dir      string @[required]
	build_dir       string @[required]
	manifest        ViteManifest
	manifest_loaded bool
}

pub struct ViteAsset {
	file             string @[required]
	name             string
	src              string
	is_entry         bool
	is_dynamic_entry bool
	css              []string
	imports          []string
	dynamic_imports  []string
}

pub type ViteManifest = map[string]ViteAsset

pub fn Vite.new(config ViteConfig) Vite {
	return Vite{
		manifest_file: config.manifest_file
		hot_file:      config.hot_file
		public_dir:    config.public_dir
		build_dir:     config.build_dir
	}
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

	if v.is_hot() {
		render = v.hot_scripts(options)
	}

	for name in names {
		render = '${render}${v.asset(name)}'
	}
	return render
}

pub fn (mut v Vite) asset(name string) veb.RawHtml {
	return v.asset_opt(name) or {
		eprintln(err)
		''
	}
}

pub fn (mut v Vite) asset_opt(name string) !veb.RawHtml {
	mut base := ''
	mut html := ''

	if !v.is_hot() {
		asset := v.chunk_opt(name)!
		css := asset.css
		imports := asset.imports

		for css_file in css {
			html += v.style(base + css_file)
		}

		for chunk in imports {
			html += if v.is_css(chunk) {
				v.style(base + chunk)
			} else if v.is_js(chunk) {
				v.preload(base + chunk)
			} else {
				''
			}
		}
	}

	html += v.tag(name)

	return html
}

pub fn (mut v Vite) url(path string) string {
	return v.url_opt(path) or {
		eprintln(err)
		''
	}
}

pub fn (mut v Vite) url_or_panic(path string) string {
	return v.url_opt(path) or { panic(err) }
}

pub fn (mut v Vite) url_opt(path string) !string {
	return if v.is_hot() {
		'${v.app_url()}/${path}'
	} else {
		asset := v.chunk_opt(path)!
		file := asset.file

		if file == '' {
			error('Unable to locate asset ${path} in Vite manifest.')
		}

		'${v.app_url()}/${v.build_dir}/${file}'
	}
}

pub fn (mut v Vite) tag(path string) string {
	return v.tag_opt(path) or {
		eprintln(err)
		''
	}
}

pub fn (mut v Vite) tag_or_panic(path string) string {
	return v.tag_opt(path) or { panic(err) }
}

pub fn (mut v Vite) tag_opt(path string) !string {
	url := v.url_opt(path)!

	return if v.is_css(path) {
		v.style(url)
	} else if v.is_js(path) {
		v.defer_script(url, '')
	} else {
		url
	}
}

pub fn (mut v Vite) chunk(name string) ViteAsset {
	return v.chunk_opt(name) or {
		eprintln(err)
		ViteAsset{
			file: ''
			name: name
		}
	}
}

pub fn (mut v Vite) chunk_opt(name string) !ViteAsset {
	manifest := v.manifest()!

	return manifest[name]
}

pub fn (mut v Vite) chunk_or_panic(name string) ViteAsset {
	return v.chunk_opt(name) or { panic(err) }
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

fn (v Vite) is_js(path string) bool {
	return match os.file_ext(path) {
		'.js', '.cjs', '.mjs', '.jsx', '.ts', '.tsx', '.cts', '.mts' {
			true
		}
		else {
			false
		}
	}
}

pub fn (v Vite) hot_scripts(options AssetOptions) veb.RawHtml {
	mut render := v.script('${v.app_url()}/@vite/client', '')

	if options.use_react {
		render = '${render}${v.react_script()}'
	}

	return render
}

pub fn (v Vite) react_script() veb.RawHtml {
	mut content := ''
	content += 'import RefreshRuntime from "${v.app_url()}/@react-refresh";'
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

pub fn (v Vite) is_hot() bool {
	return os.is_file(v.hot_path())
}

pub fn (v Vite) app_url() string {
	return v.app_url_opt() or {
		eprintln(err)
		''
	}
}

pub fn (v Vite) app_url_opt() !string {
	return if v.is_hot() {
		hot_file := v.hot_path().trim_space()
		os.read_file(hot_file) or { error('Unable to read hot file ${hot_file}: ${err}') }
	} else {
		os.getenv('APP_URL')
	}
}

pub fn (mut v Vite) manifest() !ViteManifest {
	if !v.manifest_loaded {
		v.load_manifest()!

		v.manifest_loaded = true
	}

	return v.manifest
}

fn (mut v Vite) load_manifest() ! {
	manifest_path := v.manifest_path()

	if !os.is_file(manifest_path) {
		error('Vite manifest ${manifest_path} not found.')
	}

	v.manifest = json.decode(ViteManifest, os.read_file(manifest_path)!)!

	v.add_manifest_assets()!
}

fn (mut v Vite) add_manifest_assets() ! {
	for name, asset in v.manifest {
		file := asset.file
		if v.is_css(name) {
			v.add_css(file, name)!
		} else if v.is_js(name) {
			v.add_js(file, name)!
		}
	}
}

pub fn (mut v Vite) add_css(file string, name string) ! {
	v.add(.css, file, name)!
}

pub fn (mut v Vite) add_js(file string, name string) ! {
	v.add(.js, file, name)!
}
